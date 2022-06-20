# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['TerraformState'] do
  it { expect(described_class.graphql_name).to eq('TerraformState') }
  it { expect(described_class).to require_graphql_authorizations(:read_terraform_state) }

  describe 'fields' do
    let(:fields) { %i[id name locked_by_user locked_at latest_version created_at updated_at deleted_at] }

    it { expect(described_class).to have_graphql_fields(fields) }

    it { expect(described_class.fields['id'].type).to be_non_null }
    it { expect(described_class.fields['name'].type).to be_non_null }
    it { expect(described_class.fields['lockedByUser'].type).not_to be_non_null }
    it { expect(described_class.fields['lockedAt'].type).not_to be_non_null }
    it { expect(described_class.fields['createdAt'].type).to be_non_null }
    it { expect(described_class.fields['updatedAt'].type).to be_non_null }
    it { expect(described_class.fields['deletedAt'].type).not_to be_non_null }

    it { expect(described_class.fields['latestVersion'].type).not_to be_non_null }
    it { expect(described_class.fields['latestVersion'].complexity).to eq(3) }
  end
end
