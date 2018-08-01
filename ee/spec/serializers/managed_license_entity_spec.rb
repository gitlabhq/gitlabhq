# frozen_string_literal: true

require 'spec_helper'

describe ManagedLicenseEntity do
  let(:software_license_policy) { create(:software_license_policy) }
  let(:entity) { described_class.new(software_license_policy) }

  describe '#as_json' do
    subject { entity.as_json }

    it 'contains required fields' do
      expect(subject).to include(:id, :name, :approval_status)
    end
  end
end
