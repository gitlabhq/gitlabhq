# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "User Feed", feature_category: :devops_reports do
  describe "GET /" do
    let!(:user) { create(:user) }

    context 'user atom feed via personal access token' do
      it "renders user atom feed" do
        personal_access_token = create(:personal_access_token, user: user)

        visit user_path(user, :atom, private_token: personal_access_token.token)
        expect(body).to have_selector('feed title')
      end
    end

    context 'user atom feed via feed token' do
      it "renders user atom feed" do
        visit user_path(user, :atom, feed_token: user.feed_token)
        expect(body).to have_selector('feed title')
      end
    end

    context 'feed content' do
      let(:project) { create(:project, :repository) }
      let(:issue) do
        create(
          :issue,
          project: project,
          author: user,
          description: "Houston, we have a bug!\n\n***\n\nI guess."
        )
      end

      let(:note) do
        create(
          :note,
          noteable: issue,
          author: user,
          note: 'Bug confirmed :+1:',
          project: project
        )
      end

      let(:merge_request) do
        create(
          :merge_request,
          title: 'Fix bug',
          author: user,
          source_project: project,
          target_project: project,
          description: "Here is the fix: ![an image](image.png)"
        )
      end

      let(:push_event) { create(:push_event, project: project, author: user) }
      let!(:push_event_payload) { create(:push_event_payload, event: push_event) }

      before do
        project.add_maintainer(user)
        issue_event(issue, user)
        note_event(note, user)
        merge_request_event(merge_request, user)
        visit user_path(user, :atom, feed_token: user.feed_token)
      end

      it 'has issue opened event' do
        expect(body).to have_content("#{safe_name} opened issue ##{issue.iid}")
      end

      it 'has issue comment event' do
        expect(body)
          .to have_content("#{safe_name} commented on issue ##{issue.iid}")
      end

      it 'has XHTML summaries in issue descriptions' do
        expect(body).to match %r{<hr ?/>}
      end

      it 'has XHTML summaries in notes' do
        expect(body).to match(/Bug confirmed <gl-emoji[^>]*>/)
      end

      it 'has XHTML summaries in merge request descriptions' do
        expect(body).to match %r{Here is the fix: <a[^>]*><img[^>]*/></a>}
      end

      it 'has push event commit ID' do
        expect(body).to have_content(Commit.truncate_sha(push_event.commit_id))
      end
    end
  end

  def issue_event(issue, user)
    EventCreateService.new.open_issue(issue, user)
  end

  def note_event(note, user)
    EventCreateService.new.leave_note(note, user)
  end

  def merge_request_event(request, user)
    EventCreateService.new.open_mr(request, user)
  end

  def safe_name
    html_escape(user.name)
  end
end
