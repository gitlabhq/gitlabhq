require 'spec_helper'

describe EpicsHelper do
  include ApplicationHelper

  describe '#epic_show_app_data' do
    let(:user) { create(:user) }
    let!(:epic) { create(:epic, author: user) }

    before do
      allow(helper).to receive(:current_user).and_return(user)
      stub_licensed_features(epics: true)
    end

    it 'returns the correct json' do
      data = helper.epic_show_app_data(epic, initial: {}, author_icon: 'icon_path')
      meta_data = JSON.parse(data[:meta])

      expected_keys = %i(initial meta namespace labels_path toggle_subscription_path labels_web_url epics_web_url)
      expect(data.keys).to match_array(expected_keys)
      expect(meta_data.keys).to match_array(%w[created author start_date end_date due_date epic_id todo_exists todo_path])
      expect(meta_data['author']).to eq({
        'name' => user.name,
        'url' => "/#{user.username}",
        'username' => "@#{user.username}",
        'src' => 'icon_path'
      })
    end

    context 'when user has edit permission' do
      let(:milestone) { create(:milestone, title: 'make me a sandwich') }

      let!(:epic) do
        create(
          :epic,
          author: user,
          start_date_sourcing_milestone: milestone,
          start_date: Date.new(2000, 1, 1),
          due_date_sourcing_milestone: milestone,
          due_date: Date.new(2000, 1, 2)
        )
      end

      before do
        epic.group.add_developer(user)
      end

      it 'returns extra date fields if user can edit' do
        data = helper.epic_show_app_data(epic, initial: {}, author_icon: 'icon_path')
        meta_data = JSON.parse(data[:meta])

        expect(meta_data.keys).to match_array(%w[
          created author epic_id todo_exists todo_path
          start_date start_date_fixed start_date_is_fixed start_date_from_milestones start_date_sourcing_milestone_title
          end_date due_date due_date_fixed due_date_is_fixed due_date_from_milestones due_date_sourcing_milestone_title
        ])
        expect(meta_data['start_date']).to eq('2000-01-01')
        expect(meta_data['start_date_sourcing_milestone_title']).to eq(milestone.title)
        expect(meta_data['due_date']).to eq('2000-01-02')
        expect(meta_data['due_date_sourcing_milestone_title']).to eq(milestone.title)
      end
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
