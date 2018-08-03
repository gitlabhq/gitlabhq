# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Packages::PackageFile, type: :model do
  describe 'relationships' do
    it { is_expected.to belong_to(:package) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:package) }
  end
end
