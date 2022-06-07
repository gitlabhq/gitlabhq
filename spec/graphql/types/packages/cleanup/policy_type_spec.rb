# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['PackagesCleanupPolicy'] do
  specify { expect(described_class.graphql_name).to eq('PackagesCleanupPolicy') }

  specify do
    expect(described_class.description)
      .to eq('A packages cleanup policy designed to keep only packages and packages assets that matter most')
  end

  specify { expect(described_class).to require_graphql_authorizations(:admin_package) }

  describe 'keep_n_duplicated_package_files' do
    subject { described_class.fields['keepNDuplicatedPackageFiles'] }

    it { is_expected.to have_non_null_graphql_type(Types::Packages::Cleanup::KeepDuplicatedPackageFilesEnum) }
  end

  describe 'next_run_at' do
    subject { described_class.fields['nextRunAt'] }

    it { is_expected.to have_nullable_graphql_type(Types::TimeType) }
  end
end
