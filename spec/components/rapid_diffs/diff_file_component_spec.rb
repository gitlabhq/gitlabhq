# frozen_string_literal: true

require "spec_helper"

require_relative './shared'

RSpec.describe RapidDiffs::DiffFileComponent, type: :component, feature_category: :code_review_workflow do
  include_context "with diff file component tests"

  describe 'header slot' do
    let_it_be(:diff_file) { build(:diff_file) }

    it 'renders the default header when no custom header is provided' do
      allow_next_instance_of(
        RapidDiffs::DiffFileHeaderComponent,
        diff_file: diff_file,
        environment: nil
      ) do |instance|
        allow(instance).to receive(:render_in).and_return('diff-file-header')
      end

      result = render_component

      expect(result.to_html).to include('diff-file-header')
    end

    it 'renders a custom header when provided' do
      custom_header = '<div class="custom-header">Custom Header</div>'.html_safe

      result = render_component do |c|
        c.with_header { custom_header }
      end

      expect(result.css('.custom-header').text).to eq('Custom Header')
    end

    context 'with environment' do
      let_it_be(:project) { build_stubbed(:project, :repository) }
      let_it_be(:environment) { build_stubbed(:environment, project: project) }

      it 'renders the default header with environment when no custom header is provided' do
        allow_next_instance_of(
          RapidDiffs::DiffFileHeaderComponent,
          diff_file: diff_file,
          environment: environment
        ) do |instance|
          allow(instance).to receive(:render_in).and_return('diff-file-header-with-env')
        end

        result = render_component(environment: environment)

        expect(result.to_html).to include('diff-file-header-with-env')
      end
    end
  end

  describe 'extra_file_data' do
    let_it_be(:diff_file) { build(:diff_file) }

    it 'merges extra_file_data into file_data' do
      extra_data = { custom_field: 'custom_value', another_field: 123 }

      result = render_component(extra_file_data: extra_data)

      web_component = result.at_css('diff-file')
      file_data = Gitlab::Json.safe_parse(web_component['data-file-data'])

      expect(file_data['custom_field']).to eq('custom_value')
      expect(file_data['another_field']).to eq(123)
    end
  end

  describe 'extra_options' do
    let_it_be(:diff_file) { build(:diff_file) }

    it 'merges extra classes with base classes' do
      extra_options = { class: 'custom-class another-class' }

      result = render_component(extra_options: extra_options)

      web_component = result.at_css('diff-file')
      classes = web_component['class'].split

      expect(classes).to include('rd-diff-file-component')
      expect(classes).to include('custom-class')
      expect(classes).to include('another-class')
    end

    it 'merges extra data attributes with base data attributes' do
      extra_options = { data: { custom_attr: 'custom_value', another: 123 } }

      result = render_component(extra_options: extra_options)

      web_component = result.at_css('diff-file')

      expect(web_component['data-testid']).to eq('rd-diff-file')
      expect(web_component['data-file-data']).to be_present
      expect(web_component['data-custom-attr']).to eq('custom_value')
      expect(web_component['data-another']).to eq('123')
    end

    it 'accepts array of classes' do
      extra_options = { class: %w[class-one class-two] }

      result = render_component(extra_options: extra_options)

      web_component = result.at_css('diff-file')
      classes = web_component['class'].split

      expect(classes).to include('rd-diff-file-component')
      expect(classes).to include('class-one')
      expect(classes).to include('class-two')
    end
  end

  def render_component(**args, &block)
    render_inline(described_class.new(diff_file: diff_file, plain_view: true, **args), &block)
  end
end
