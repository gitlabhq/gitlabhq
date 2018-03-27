require 'spec_helper'

describe InstanceConfigurationHelper do
  describe '#instance_configuration_cell_html' do
    describe 'if not block is passed' do
      it 'returns the parameter if present' do
        expect(helper.instance_configuration_cell_html('gitlab')).to eq('gitlab')
      end

      it 'returns "-" if the parameter is blank' do
        expect(helper.instance_configuration_cell_html(nil)).to eq('-')
        expect(helper.instance_configuration_cell_html('')).to eq('-')
      end
    end

    describe 'if a block is passed' do
      let(:upcase_block) { ->(value) { value.upcase } }

      it 'returns the result of the block' do
        expect(helper.instance_configuration_cell_html('gitlab', &upcase_block)).to eq('GITLAB')
        expect(helper.instance_configuration_cell_html('gitlab') { |v| v.upcase }).to eq('GITLAB')
      end

      it 'returns "-" if the parameter is blank' do
        expect(helper.instance_configuration_cell_html(nil, &upcase_block)).to eq('-')
        expect(helper.instance_configuration_cell_html(nil) { |v| v.upcase }).to eq('-')
        expect(helper.instance_configuration_cell_html('', &upcase_block)).to eq('-')
      end
    end

    it 'boolean are valid values to display' do
      expect(helper.instance_configuration_cell_html(true)).to eq(true)
      expect(helper.instance_configuration_cell_html(false)).to eq(false)
    end
  end

  describe '#instance_configuration_human_size_cell' do
    it 'returns "-" if the parameter is blank' do
      expect(helper.instance_configuration_human_size_cell(nil)).to eq('-')
      expect(helper.instance_configuration_human_size_cell('')).to eq('-')
    end

    it 'accepts the value in bytes' do
      expect(helper.instance_configuration_human_size_cell(1024)).to eq('1 KB')
    end

    it 'returns the value in human size readable format' do
      expect(helper.instance_configuration_human_size_cell(1048576)).to eq('1 MB')
    end
  end
end
