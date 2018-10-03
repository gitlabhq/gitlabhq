# frozen_string_literal: true

require 'spec_helper'

describe Vulnerabilities::OccurrenceIdentifier do
  describe 'associations' do
    it { is_expected.to belong_to(:identifier).class_name('Vulnerabilities::Identifier') }
    it { is_expected.to belong_to(:occurrence).class_name('Vulnerabilities::Occurrence') }
  end

  describe 'validations' do
    let!(:occurrence_identifier) { create(:vulnerabilities_occurrence_identifier) }

    it { is_expected.to validate_presence_of(:occurrence) }
    it { is_expected.to validate_presence_of(:identifier) }
    it { is_expected.to validate_uniqueness_of(:identifier_id).scoped_to(:occurrence_id) }
  end
end
