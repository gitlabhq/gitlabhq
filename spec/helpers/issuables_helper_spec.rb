require 'spec_helper'

describe IssuablesHelper do 
  let(:label)  { build_stubbed(:label) }
  let(:label2) { build_stubbed(:label) }

  context 'label tooltip' do
    it 'returns label text' do
      expect(issuable_labels_tooltip([label])).to eq(label.title)
    end

    it 'returns label text' do
      expect(issuable_labels_tooltip([label, label2], limit: 1)).to eq("#{label.title}, and 1 more")
    end
  end
end
