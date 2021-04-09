# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ConanMetadatumFileTypeEnum'] do
  it 'uses all possible options from model' do
    expected_keys = ::Packages::Conan::FileMetadatum.conan_file_types
      .keys
      .map(&:upcase)

    expect(described_class.values.keys).to contain_exactly(*expected_keys)
  end
end
