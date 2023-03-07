# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['DesignAtVersion'], feature_category: :portfolio_management do
  it_behaves_like 'a GraphQL type with design fields' do
    let(:extra_design_fields) { %i[version design] }
    let_it_be(:design) { create(:design, :with_versions) }
    let(:object_id) do
      version = design.versions.first
      GitlabSchema.id_from_object(create(:design_at_version, design: design, version: version))
    end

    let_it_be(:object_id_b) { GitlabSchema.id_from_object(create(:design_at_version)) }
    let(:object_type) { ::Types::DesignManagement::DesignAtVersionType }
  end
end
