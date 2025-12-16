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

  def render_component(**args, &block)
    render_inline(described_class.new(diff_file: diff_file, **args), &block)
  end
end
