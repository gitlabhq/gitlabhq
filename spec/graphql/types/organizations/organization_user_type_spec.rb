# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['OrganizationUser'], feature_category: :organization do
  let(:expected_fields) { %w[access_level badges id is_last_owner user user_permissions] }

  specify { expect(described_class.graphql_name).to eq('OrganizationUser') }
  specify { expect(described_class).to require_graphql_authorizations(:read_organization_user) }
  specify { expect(described_class).to have_graphql_fields(*expected_fields) }

  describe 'field authorization' do
    %w[accessLevel isLastOwner].each do |field_name|
      it "requires read_user_access_level for #{field_name}" do
        expect(described_class.fields[field_name].instance_variable_get(:@authorize))
          .to contain_exactly(:read_user_access_level)
      end
    end
  end
end
