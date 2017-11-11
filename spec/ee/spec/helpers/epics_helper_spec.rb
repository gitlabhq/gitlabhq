require 'spec_helper'

describe EpicsHelper do
  include ApplicationHelper

  describe '#epic_meta_data' do
    it 'returns the correct json' do
      user = create(:user)
      @epic = create(:epic, author: user)

      expect(JSON.parse(epic_meta_data).keys).to match_array(%w[created author start_date end_date])
      expect(JSON.parse(epic_meta_data)['author']).to eq({
        'name' => user.name,
        'url' => "/#{user.username}",
        'username' => "@#{user.username}",
        'src' => "#{avatar_icon(user)}"
      })
    end
  end
end
