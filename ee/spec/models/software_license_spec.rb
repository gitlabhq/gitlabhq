# frozen_string_literal: true

require 'spec_helper'

describe SoftwareLicense do
  subject { build(:software_license) }

  describe 'validations' do
    it { is_expected.to include_module(Presentable) }
    it { is_expected.to validate_presence_of(:name) }
  end
end
