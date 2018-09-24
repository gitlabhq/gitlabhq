# frozen_string_literal: true

require 'spec_helper'

describe Vulnerabilities::Identifier do
  describe 'associations' do
    it { is_expected.to have_many(:occurrence_identifiers).class_name('Vulnerabilities::OccurrenceIdentifier') }
    it { is_expected.to have_many(:occurrences).class_name('Vulnerabilities::Occurrence') }
    it { is_expected.to have_many(:primary_occurrences).class_name('Vulnerabilities::Occurrence') }
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    let!(:identifier) { create(:vulnerabilities_identifier) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:external_type) }
    it { is_expected.to validate_presence_of(:external_id) }
    it { is_expected.to validate_presence_of(:fingerprint) }
    # Uniqueness validation doesn't work with binary columns. See TODO in class file
    # it { is_expected.to validate_uniqueness_of(:fingerprint).scoped_to(:project_id) }
  end
end
