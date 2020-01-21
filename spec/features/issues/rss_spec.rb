# frozen_string_literal: true

require 'spec_helper'

describe 'Project Issues RSS' do
  let!(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:project) { create(:project, group: group, visibility_level: Gitlab::VisibilityLevel::PUBLIC) }
  let(:path) { project_issues_path(project) }

  before do
    create(:issue, project: project, assignees: [user])
    group.add_developer(user)
  end

  context 'when signed in' do
    let(:user) { create(:user) }

    before do
      project.add_developer(user)
      sign_in(user)
      visit path
    end

    it_behaves_like "it has an RSS button with current_user's feed token"
    it_behaves_like "an autodiscoverable RSS feed with current_user's feed token"
  end

  context 'when signed out' do
    before do
      visit path
    end

    it_behaves_like "it has an RSS button without a feed token"
    it_behaves_like "an autodiscoverable RSS feed without a feed token"
  end

  describe 'feeds' do
    shared_examples 'updates atom feed link' do |type|
      it "for #{type}" do
        sign_in(user)
        visit path

        link = find_link('Subscribe to RSS feed')
        params = CGI.parse(URI.parse(link[:href]).query)
        auto_discovery_link = find('link[type="application/atom+xml"]', visible: false)
        auto_discovery_params = CGI.parse(URI.parse(auto_discovery_link[:href]).query)

        expected = {
          'feed_token' => [user.feed_token],
          'assignee_id' => [user.id.to_s]
        }

        expect(params).to include(expected)
        expect(auto_discovery_params).to include(expected)
      end
    end

    it_behaves_like 'updates atom feed link', :project do
      let(:path) { project_issues_path(project, assignee_id: user.id) }
    end

    it_behaves_like 'updates atom feed link', :group do
      let(:path) { issues_group_path(group, assignee_id: user.id) }
    end
  end
end
