# frozen_string_literal: true

if ENV.key?('BENCHMARK')
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
  RSpec.describe 'GitLab Markdown Benchmark', :aggregate_failures do
    include MarkupHelper

    let_it_be(:feature)       { MarkdownFeature.new }
    let_it_be(:project)       { feature.project }
    let_it_be(:group)         { feature.group }
    let_it_be(:wiki)          { feature.wiki }
    let_it_be(:wiki_page)     { feature.wiki_page }
    let_it_be(:markdown_text) { feature.raw_markdown }

    let!(:render_context) { Banzai::RenderContext.new(project, current_user) }

    before do
      stub_application_setting(asset_proxy_enabled: true)
      stub_application_setting(asset_proxy_secret_key: 'shared-secret')
      stub_application_setting(asset_proxy_url: 'https://assets.example.com')
      stub_application_setting(asset_proxy_whitelist: %w(gitlab.com *.mydomain.com))

      Banzai::Filter::AssetProxyFilter.initialize_settings
    end

    context 'pipelines' do
      it 'benchmarks several pipelines' do
        path = 'images/example.jpg'
        gitaly_wiki_file = Gitlab::GitalyClient::WikiFile.new(path: path)
        allow(wiki).to receive(:find_file).with(path).and_return(Gitlab::Git::WikiFile.new(gitaly_wiki_file))
        allow(wiki).to receive(:wiki_base_path) { '/namespace1/gitlabhq/wikis' }

        puts "\n--> Benchmarking Full, Wiki, and Plain pipelines\n"

        Benchmark.ips do |x|
          x.config(time: 10, warmup: 2)

          x.report('Full pipeline') { markdown(markdown_text, { pipeline: :full }) }
          x.report('Wiki pipeline') { markdown(markdown_text, { pipeline: :wiki, wiki: wiki, page_slug: wiki_page.slug }) }
          x.report('Plain pipeline') { markdown(markdown_text, { pipeline: :plain_markdown }) }

          x.compare!
        end
      end
    end

    context 'filters' do
      let(:context) do
        tmp = { project: project, current_user: current_user, render_context: render_context }
        Banzai::Filter::AssetProxyFilter.transform_context(tmp)
      end

      it 'benchmarks all filters in the FullPipeline' do
        benchmark_pipeline_filters(:full)
      end

      it 'benchmarks all filters in the PlainMarkdownPipeline' do
        benchmark_pipeline_filters(:plain_markdown)
      end
    end

    # build up the source text for each filter
    def build_filter_text(pipeline, initial_text)
      filter_source = {}
      input_text    = initial_text

      pipeline.filters.each do |filter_klass|
        filter_source[filter_klass] = input_text

        output = filter_klass.call(input_text, context)
        input_text = output
      end

      filter_source
    end

    def benchmark_pipeline_filters(pipeline_type)
      pipeline      = Banzai::Pipeline[pipeline_type]
      filter_source = build_filter_text(pipeline, markdown_text)

      puts "\n--> Benchmarking #{pipeline.name.demodulize} filters\n"

      Benchmark.ips do |x|
        x.config(time: 10, warmup: 2)

        pipeline.filters.each do |filter_klass|
          label = filter_klass.name.demodulize.delete_suffix('Filter').truncate(20)

          x.report(label) { filter_klass.call(filter_source[filter_klass], context) }
        end

        x.compare!
      end
    end

    # Fake a `current_user` helper
    def current_user
      feature.user
    end
  end
end
