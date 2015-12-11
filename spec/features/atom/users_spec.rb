require 'spec_helper'

describe "User Feed", feature: true  do
  describe "GET /" do
    let!(:user) { create(:user) }

    context 'user atom feed via private token' do
      it "should render user atom feed" do
        visit user_path(user, :atom, private_token: user.private_token)
        expect(body).to have_selector('feed title')
      end
    end

    context 'feed content' do
      let(:project) { create(:project) }
      let(:issue) do
        create(:issue,
               project: project,
               author: user,
               description: "Houston, we have a bug!\n\n***\n\nI guess.")
      end
      let(:note) do
        create(:note,
               noteable: issue,
               author: user,
               note: 'Bug confirmed :+1:',
               project: project)
      end
      let(:merge_request) do
        create(:merge_request,
               title: 'Fix bug',
               author: user,
               source_project: project,
               target_project: project,
               description: "Here is the fix: ![an image](image.png)")
      end

      before do
        project.team << [user, :master]
        issue_event(issue, user)
        note_event(note, user)
        merge_request_event(merge_request, user)
        visit user_path(user, :atom, private_token: user.private_token)
      end

      it 'should have issue opened event' do
        expect(body).to have_content("#{safe_name} opened issue ##{issue.iid}")
      end

      it 'should have issue comment event' do
        expect(body).
          to have_content("#{safe_name} commented on issue ##{issue.iid}")
      end

      it 'should have XHTML summaries in issue descriptions' do
        expect(body).to match /we have a bug!<\/p>\n\n<hr ?\/>\n\n<p>I guess/
      end

      it 'should have XHTML summaries in notes' do
        expect(body).to match /Bug confirmed <img[^>]*\/>/
      end

      it 'should have XHTML summaries in merge request descriptions' do
        expect(body).to match /Here is the fix: <img[^>]*\/>/
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
