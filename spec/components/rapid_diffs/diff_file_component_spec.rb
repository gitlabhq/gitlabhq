# frozen_string_literal: true

require "spec_helper"

require_relative './shared'

RSpec.describe RapidDiffs::DiffFileComponent, type: :component, feature_category: :code_review_workflow do
  include_context "with diff file component tests"

  def render_component(**args)
    render_inline(described_class.new(diff_file: diff_file, **args))
  end
end
