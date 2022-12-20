# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Dashboard Feed", feature_category: :devops_reports do
  describe "GET /" do
    let!(:user) { create(:user, name: "Jonh") }

    context "projects atom feed via personal access token" do
      it "renders projects atom feed" do
        personal_access_token = create(:personal_access_token, user: user)

        visit dashboard_projects_path(:atom, private_token: personal_access_token.token)
        expect(body).to have_selector('feed title')
      end
    end

    context "projects atom feed via feed token" do
      it "renders projects atom feed" do
        visit dashboard_projects_path(:atom, feed_token: user.feed_token)
        expect(body).to have_selector('feed title')
      end
    end

    context 'feed content' do
      let(:project) { create(:project) }
      let(:issue) { create(:issue, project: project, author: user, description: '') }
      let(:note) { create(:note, noteable: issue, author: user, note: 'Bug confirmed', project: project) }

      before do
        project.add_maintainer(user)
        issue_event(issue, user)
        note_event(note, user)
        visit dashboard_projects_path(:atom, feed_token: user.feed_token)
      end

      it "has issue opened event" do
        expect(body).to have_content("#{user.name} opened issue ##{issue.iid}")
      end

      it "has issue comment event" do
        expect(body)
          .to have_content("#{user.name} commented on issue ##{issue.iid}")
      end
    end
  end

  def issue_event(issue, user)
    EventCreateService.new.open_issue(issue, user)
  end

  def note_event(note, user)
    EventCreateService.new.leave_note(note, user)
  end
end
