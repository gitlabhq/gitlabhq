# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['PackageTypeEnum'] do
  it 'exposes all package types' do
    expect(described_class.values.keys).to contain_exactly(*%w[MAVEN NPM CONAN NUGET PYPI COMPOSER GENERIC GOLANG DEBIAN RUBYGEMS HELM TERRAFORM_MODULE RPM ML_MODEL])
  end
end
