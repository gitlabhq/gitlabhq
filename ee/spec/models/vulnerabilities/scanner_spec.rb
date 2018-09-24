# frozen_string_literal: true

require 'spec_helper'

describe Vulnerabilities::Scanner do
  describe 'associations' do
    it { is_expected.to have_many(:occurrences).class_name('Vulnerabilities::Occurrence') }
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    let!(:scanner) { create(:vulnerabilities_scanner) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_uniqueness_of(:external_id).scoped_to(:project_id) }
  end
end
