# frozen_string_literal: true

return unless ENV.key?('BENCHMARK')

require 'spec_helper'
require 'erb'
require 'benchmark/ips'

# This benchmarks some of the Banzai pipelines and filters.
# They are not definitive, but can be used by a developer to
# get a rough idea how the changing or addition of a new filter
# will effect performance.
#
# Run by:
#   BENCHMARK=1 rspec spec/benchmarks/banzai_benchmark.rb
# or
#   rake benchmark:banzai
#
# A specific filter can also be benchmarked by using the `FILTER`
# environment variable.
#
#   BENCHMARK=1 FILTER=MathFilter rspec spec/benchmarks/banzai_benchmark.rb --tag specific_filter
# or
#   FILTER=MathFilter rake benchmark:banzai
#
# rubocop: disable RSpec/TopLevelDescribePath
RSpec.describe 'GitLab Markdown Benchmark', :aggregate_failures, feature_category: :markdown do
  include MarkupHelper

  let_it_be(:feature)       { MarkdownFeature.new }
  let_it_be(:project)       { feature.project }
  let_it_be(:group)         { feature.group }
  let_it_be(:wiki)          { feature.wiki }
  let_it_be(:wiki_page)     { feature.wiki_page }
  let_it_be(:markdown_text) { feature.raw_markdown }
  let_it_be(:glfm_engine)   { Banzai::Filter::MarkdownFilter::GLFM_ENGINE }
  let_it_be(:cmark_engine)  { Banzai::Filter::MarkdownFilter::CMARK_ENGINE }
  let_it_be(:grafana_integration) { create(:grafana_integration, project: project) }
  let_it_be(:default_context) do
    {
      project: project,
      current_user: current_user,
      suggestions_filter_enabled: true
    }
  end

  let(:context) do
    Banzai::Filter::AssetProxyFilter.transform_context(default_context)
  end

  let!(:render_context) { Banzai::RenderContext.new(project, current_user) }

  before do
    stub_application_setting(asset_proxy_enabled: true)
    stub_application_setting(asset_proxy_secret_key: 'shared-secret')
    stub_application_setting(asset_proxy_url: 'https://assets.example.com')
    stub_application_setting(asset_proxy_whitelist: %w[gitlab.com *.mydomain.com])
    stub_application_setting(plantuml_enabled: true, plantuml_url: 'http://localhost:8080')
    stub_application_setting(kroki_enabled: true, kroki_url: 'http://localhost:8000')

    Banzai::Filter::AssetProxyFilter.initialize_settings
  end

  context 'pipelines' do
    it 'benchmarks several pipelines' do
      name = 'example.jpg'
      path = "images/#{name}"
      blob = instance_double('Gitlab::Git::Blob', name: name, path: path, mime_type: 'image/jpeg', data: nil)
      allow(wiki).to receive(:find_file).with(path, load_content: false).and_return(Gitlab::Git::WikiFile.new(blob))
      allow(wiki).to receive(:wiki_base_path) { '/namespace1/gitlabhq/wikis' }

      puts "\n--> Benchmarking Full, Wiki, and Plain pipelines\n"

      Benchmark.ips do |x|
        x.config(time: 10, warmup: 2)

        x.report('Full pipeline') { Banzai::Pipeline::FullPipeline.call(markdown_text, context) }
        x.report('Wiki pipeline') { Banzai::Pipeline::WikiPipeline.call(markdown_text, context.merge(wiki: wiki, page_slug: wiki_page.slug)) }
        x.report('Plain pipeline') { Banzai::Pipeline::PlainMarkdownPipeline.call(markdown_text, context) }

        x.compare!
      end
    end
  end

  context 'markdown engines' do
    it 'benchmarks full pipeline using different markdown engines' do
      puts "\n--> Benchmarking FullPipeline with Cmark and Glfm engines\n"

      Benchmark.ips do |x|
        x.config(time: 10, warmup: 2)

        x.report('glfm') { Banzai::Pipeline::FullPipeline.call(markdown_text, context.merge(markdown_engine: glfm_engine)) }
        x.report('cmark') { Banzai::Pipeline::FullPipeline.call(markdown_text, context.merge(markdown_engine: cmark_engine)) }

        x.compare!
      end
    end

    it 'benchmarks plain markdown pipeline using different markdown engines' do
      puts "\n--> Benchmarking PlainMarkdownPipeline with Cmark and Glfm engines\n"

      Benchmark.ips do |x|
        x.config(time: 10, warmup: 2)

        x.report('glfm') { Banzai::Pipeline::PlainMarkdownPipeline.call(markdown_text, context.merge(markdown_engine: glfm_engine)) }
        x.report('cmark') { Banzai::Pipeline::PlainMarkdownPipeline.call(markdown_text, context.merge(markdown_engine: cmark_engine)) }

        x.compare!
      end
    end

    it 'benchmarks MarkdownFilter using different markdown engines' do
      puts "\n--> Benchmarking MarkdownFilter with Cmark and Glfm engines\n"

      pipeline      = Banzai::Pipeline[:plain_markdown]
      filter_klass  = Banzai::Filter::MarkdownFilter
      filter_source = build_filter_text(pipeline, markdown_text)

      Benchmark.ips do |x|
        x.config(time: 10, warmup: 2)

        x.report('Markdown-glfm') do
          filter = filter_klass.new(filter_source[filter_klass][:input_text],
            context.merge(markdown_engine: glfm_engine),
            filter_source[filter_klass][:input_result])
          filter.call
        end

        x.report('Markdown-cmark') do
          filter = filter_klass.new(filter_source[filter_klass][:input_text],
            context.merge(markdown_engine: cmark_engine),
            filter_source[filter_klass][:input_result])
          filter.call
        end

        x.compare!
      end
    end
  end

  context 'filters' do
    it 'benchmarks all filters in the FullPipeline' do
      benchmark_pipeline_filters(:full)
    end

    it 'benchmarks all filters in the PlainMarkdownPipeline' do
      benchmark_pipeline_filters(:plain_markdown)
    end

    it 'benchmarks specified filters in the FullPipeline', :specific_filter do
      begin
        filter = ENV['FILTER'] || 'MarkdownFilter'
        filter_klass = "Banzai::Filter::#{filter}".constantize
      rescue NameError
        raise 'Incorrect filter specified. Correct example: FILTER=MathFilter'
      end

      benchmark_pipeline_filters(:full, [filter_klass])
    end
  end

  # build up the source text for each filter
  def build_filter_text(pipeline, initial_text)
    filter_source = {}
    input_text    = initial_text
    result        = nil

    pipeline.filters.each do |filter_klass|
      # store inputs for current filter_klass
      filter_source[filter_klass] = { input_text: input_text, input_result: result }

      filter = filter_klass.new(input_text, context, result)
      output = filter.call

      # save these for the next filter_klass
      input_text = output
      result = filter.result
    end

    filter_source
  end

  def benchmark_pipeline_filters(pipeline_type, filter_klass_list = nil)
    pipeline      = Banzai::Pipeline[pipeline_type]
    filter_source = build_filter_text(pipeline, markdown_text)

    filter_msg = filter_klass_list ? filter_klass_list.first.name.demodulize : 'all filters'
    puts "\n--> Benchmarking #{filter_msg} for #{pipeline.name.demodulize} with Glfm\n"

    Benchmark.ips do |x|
      x.config(time: 10, warmup: 2)

      filters = filter_klass_list || pipeline.filters
      filters.each do |filter_klass|
        label = filter_klass.name.demodulize.delete_suffix('Filter').truncate(20)

        x.report(label) do
          filter = filter_klass.new(filter_source[filter_klass][:input_text],
            context,
            filter_source[filter_klass][:input_result])
          filter.call
        end
      end

      x.compare!
    end
  end

  # Fake a `current_user` helper
  def current_user
    feature.user
  end
end
