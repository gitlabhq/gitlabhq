require 'spec_helper'

describe EpicsHelper do
  include ApplicationHelper

  describe '#epic_show_app_data' do
    it 'returns the correct json' do
      user = create(:user)
      @epic = create(:epic, author: user)

      data = epic_show_app_data(@epic, initial: {}, author_icon: 'icon_path')
      meta_data = JSON.parse(data[:meta])

      expected_keys = %i(initial meta namespace labels_path labels_web_url epics_web_url)
      expect(data.keys).to match_array(expected_keys)
      expect(meta_data.keys).to match_array(%w[created author start_date end_date])
      expect(meta_data['author']).to eq({
        'name' => user.name,
        'url' => "/#{user.username}",
        'username' => "@#{user.username}",
        'src' => 'icon_path'
      })
    end
  end

  describe '#epic_endpoint_query_params' do
    it 'it includes epic specific options in JSON format' do
      opts = epic_endpoint_query_params({})

      expected = "{\"only_group_labels\":true,\"include_ancestor_groups\":true,\"include_descendant_groups\":true}"
      expect(opts[:data][:endpoint_query_params]).to eq(expected)
    end
  end
end
