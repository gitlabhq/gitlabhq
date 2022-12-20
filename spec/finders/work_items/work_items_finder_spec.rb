# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::WorkItemsFinder, feature_category: :team_planning do
  using RSpec::Parameterized::TableSyntax
  include_context 'WorkItemsFinder context'

  it_behaves_like 'issues or work items finder', :work_item, 'WorkItemsFinder#execute context'
end
