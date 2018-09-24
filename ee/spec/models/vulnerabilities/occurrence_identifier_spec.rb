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

    context 'when primary' do
      before do
        allow_any_instance_of(described_class).to receive(:primary).and_return(true)
      end

      it { is_expected.to validate_uniqueness_of(:occurrence_id) }
    end

    context 'when not primary' do
      before do
        allow_any_instance_of(described_class).to receive(:primary).and_return(false)
      end

      it { is_expected.not_to validate_uniqueness_of(:occurrence_id) }
    end
  end
end
