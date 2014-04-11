require 'spec_helper'

describe LabelsHelper do
  describe '#label_css_class' do
    it 'returns label-danger when given Bug as param' do
      expect(label_css_class('bug')).to eq('label-danger')
    end

    it 'returns label-danger when given Bug as param' do
      expect(label_css_class('Bug')).to eq('label-danger')
    end
  end
end
