# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema.types['Design'] do
  it_behaves_like 'a GraphQL type with design fields' do
    let(:extra_design_fields) { %i[notes discussions versions] }
    let_it_be(:design) { create(:design, :with_versions) }
    let(:object_id) { GitlabSchema.id_from_object(design) }
    let_it_be(:object_id_b) { GitlabSchema.id_from_object(create(:design, :with_versions)) }
    let(:object_type) { ::Types::DesignManagement::DesignType }
  end
end
