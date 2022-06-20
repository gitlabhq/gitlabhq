# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['PackagesCleanupKeepDuplicatedPackageFilesEnum'] do
  it 'exposes all options' do
    expect(described_class.values.keys)
      .to contain_exactly(*Types::Packages::Cleanup::KeepDuplicatedPackageFilesEnum::OPTIONS_MAPPING.values)
  end

  it 'uses all possible options from model' do
    all_options = Packages::Cleanup::Policy::KEEP_N_DUPLICATED_PACKAGE_FILES_VALUES
    expect(described_class::OPTIONS_MAPPING.keys).to contain_exactly(*all_options)
  end
end
