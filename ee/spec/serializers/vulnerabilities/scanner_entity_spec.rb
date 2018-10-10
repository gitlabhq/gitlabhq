require 'spec_helper'

describe Vulnerabilities::ScannerEntity do
  let(:scanner) { create(:vulnerabilities_scanner) }

  let(:entity) do
    described_class.represent(scanner)
  end

  describe '#as_json' do
    subject { entity.as_json }

    it 'contains required fields' do
      expect(subject).to include(:name, :external_id)
    end
  end
end
