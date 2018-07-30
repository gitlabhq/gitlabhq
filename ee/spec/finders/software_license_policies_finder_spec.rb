# frozen_string_literal: true

require 'spec_helper'

describe SoftwareLicensePoliciesFinder do
  let(:project) { create(:project) }
  let(:software_license_policy) { create(:software_license_policy, project: project) }

  let(:user) do
    create(:user).tap do |u|
      project.add_maintainer(u)
    end
  end

  let(:finder) { described_class.new(user, project) }

  before do
    stub_licensed_features(license_management: true)
  end

  it 'finds the software license policy' do
    expect(finder.find_by_name_or_id(software_license_policy.name)).to eq(software_license_policy)
  end
end
