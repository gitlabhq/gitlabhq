# frozen_string_literal: true

require 'spec_helper'

describe SoftwareLicensePolicy do
  subject { build(:software_license_policy) }

  describe 'validations' do
    it { is_expected.to include_module(Presentable) }
    it { is_expected.to validate_presence_of(:software_license) }
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:approval_status) }
    it { is_expected.to validate_uniqueness_of(:software_license).scoped_to(:project_id).with_message(/has already been taken/) }
  end
end
