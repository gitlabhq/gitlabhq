require 'spec_helper'

describe Vulnerabilities::IdentifierEntity do
  let(:identifier) { create(:vulnerabilities_identifier) }

  let(:entity) do
    described_class.represent(identifier)
  end

  describe '#as_json' do
    subject { entity.as_json }

    it 'contains required fields' do
      expect(subject).to include(:external_type, :external_id, :name, :url)
    end
  end
end
