# frozen_string_literal: true

require "spec_helper"

RSpec.describe RapidDiffs::StreamingErrorComponent, type: :component, feature_category: :code_review_workflow do
  it "renders component with message" do
    result = render_component('Foo')
    expect(result).to have_css('streaming-error[message="Foo"]')
  end

  def render_component(message)
    render_inline(described_class.new(message: message))
  end
end
