# frozen_string_literal: true

require 'spec_helper'

describe 'EE-specific GitLab Markdown', :aggregate_failures do
  include Capybara::Node::Matchers
  include MarkupHelper
  include MarkdownMatchers

  def doc(html = @html)
    @doc ||= Nokogiri::HTML::DocumentFragment.parse(html)
  end

  before do
    stub_licensed_features(epics: true)

    @feat = ::EE::MarkdownFeature
      .new(Rails.root.join('ee/spec/fixtures/markdown.md.erb'))

    # `markdown` helper expects a `@project` and `@group` variable
    @project = @feat.project
    @group = @feat.group
  end

  context 'default pipeline' do
    before do
      @html = markdown(@feat.raw_markdown)
    end

    it 'includes custom filters' do
      aggregate_failures 'all reference filters' do
        expect(doc).to reference_epics
      end
    end
  end
end
