# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Factory default associations', feature_category: :tooling do
  row = FactoryDefaults::Row

  it_behaves_like 'factory default associations', [
    row.new(
      factory: :work_item, skip: :project, passed: { namespace: :group },
      expected: ->(group, _) { { namespace: group, project: nil } }
    ),
    row.new(
      factory: :work_item, skip: :project, passed: { namespace: :project_namespace },
      expected: ->(namespace, _) { { namespace: namespace, project: namespace.project } }
    )
  ]
end
