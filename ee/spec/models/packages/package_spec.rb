# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Packages::Package, type: :model do
  describe 'relationships' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to have_many(:package_files) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
  end
end
