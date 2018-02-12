require 'spec_helper'

describe AuditEventsHelper do
  describe '#human_text' do
    let(:details) do
      {
        remove: 'user_access',
        author_name: 'John Doe',
        target_id: 1,
        target_type: 'User',
        target_details: 'Michael'
      }
    end

    it 'ignores keys that start with start with author_, or target_' do
      expect(human_text(details)).to eq 'Remove <strong>user access</strong>    '
    end
  end

  describe '#select_keys' do
    it 'returns empty string if key starts with author_' do
      expect(select_keys('author_name', 'John Doe')).to eq ''
    end

    it 'returns empty string if key starts with target_' do
      expect(select_keys('target_name', 'John Doe')).to eq ''
    end

    it 'returns formatted text if key does not start with author_, or target_' do
      expect(select_keys('remove', 'user_access')).to eq 'remove <strong>user_access</strong>'
    end
  end
end
