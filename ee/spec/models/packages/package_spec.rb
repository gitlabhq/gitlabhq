# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Packages::Package, type: :model do
  describe 'relationships' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to have_many(:package_files) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }

    describe '#name' do
      it { is_expected.to allow_value("my/domain/com/my-app").for(:name) }
      it { is_expected.to allow_value("my.app-11.07.2018").for(:name) }
      it { is_expected.to_not allow_value("my(dom$$$ain)com.my-app").for(:name) }
    end
  end
end
