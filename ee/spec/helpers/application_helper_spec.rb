require 'spec_helper'

describe ApplicationHelper do
  describe '#autocomplete_data_sources' do
    let(:object) { create(:group) }
    let(:noteable_type) { Epic }
    it 'returns paths for autocomplete_sources_controller' do
      sources = helper.autocomplete_data_sources(object, noteable_type)
      expect(sources.keys).to match_array([:members])
      sources.keys.each do |key|
        expect(sources[key]).not_to be_nil
      end
    end
  end
end
