# frozen_string_literal: true

require "spec_helper"

require_relative './shared'

RSpec.describe RapidDiffs::MergeRequestDiffFileComponent, type: :component, feature_category: :code_review_workflow do
  include_context "with diff file component tests"
  let_it_be(:merge_request) { build(:merge_request) }

  def render_component(**args)
    render_inline(described_class.new(diff_file:, merge_request:, **args))
  end
end
