require "spec_helper"

describe IssuesHelper do
  let(:project) { create(:project) }
  let(:issue) { create :issue, project: project }
  let(:ext_project) { create :redmine_project }

  describe "url_for_issue" do
    let(:issues_url) { ext_project.external_issue_tracker.issues_url}
    let(:ext_expected) { issues_url.gsub(':id', issue.iid.to_s).gsub(':project_id', ext_project.id.to_s) }
    let(:int_expected) { polymorphic_path([@project.namespace, @project, issue]) }

    it "returns internal path if used internal tracker" do
      @project = project

      expect(url_for_issue(issue.iid)).to match(int_expected)
    end

    it "returns path to external tracker" do
      @project = ext_project

      expect(url_for_issue(issue.iid)).to match(ext_expected)
    end

    it "returns path to internal issue when internal option passed" do
      @project = ext_project

      expect(url_for_issue(issue.iid, ext_project, internal: true)).to match(int_expected)
    end

    it "returns empty string if project nil" do
      @project = nil

      expect(url_for_issue(issue.iid)).to eq ""
    end

    it 'returns an empty string if issue_url is invalid' do
      expect(project).to receive_message_chain('issues_tracker.issue_url') { 'javascript:alert("foo");' }

      expect(url_for_issue(issue.iid, project)).to eq ''
    end

    it 'returns an empty string if issue_path is invalid' do
      expect(project).to receive_message_chain('issues_tracker.issue_path') { 'javascript:alert("foo");' }

      expect(url_for_issue(issue.iid, project, only_path: true)).to eq ''
    end

    describe "when external tracker was enabled and then config removed" do
      before do
        @project = ext_project
        allow(Gitlab.config).to receive(:issues_tracker).and_return(nil)
      end

      it "returns external path" do
        expect(url_for_issue(issue.iid)).to match(ext_expected)
      end
    end
  end

  describe '#award_user_list' do
    it "returns a comma-separated list of the first X users" do
      user = build_stubbed(:user, name: 'Joe')
      awards = Array.new(3, build_stubbed(:award_emoji, user: user))

      expect(award_user_list(awards, nil, limit: 3))
        .to eq('Joe, Joe, and Joe')
    end

    it "displays the current user's name as 'You'" do
      user = build_stubbed(:user, name: 'Joe')
      award = build_stubbed(:award_emoji, user: user)

      expect(award_user_list([award], user)).to eq('You')
      expect(award_user_list([award], nil)).to eq 'Joe'
    end

    it "truncates lists" do
      user = build_stubbed(:user, name: 'Jane')
      awards = Array.new(5, build_stubbed(:award_emoji, user: user))

      expect(award_user_list(awards, nil, limit: 3))
        .to eq('Jane, Jane, Jane, and 2 more.')
    end

    it "displays the current user in front of other users" do
      current_user = build_stubbed(:user)
      my_award = build_stubbed(:award_emoji, user: current_user)
      award = build_stubbed(:award_emoji, user: build_stubbed(:user, name: 'Jane'))
      awards = Array.new(5, award).push(my_award)

      expect(award_user_list(awards, current_user, limit: 2))
        .to eq("You, Jane, and 4 more.")
    end
  end

  describe '#award_state_class' do
    let!(:upvote) { create(:award_emoji) }

    it "returns disabled string for unauthenticated user" do
      expect(award_state_class(AwardEmoji.all, nil)).to eq("disabled")
    end

    it "returns active string for author" do
      expect(award_state_class(AwardEmoji.all, upvote.user)).to eq("active")
    end
  end

  describe "awards_sort" do
    it "sorts a hash so thumbsup and thumbsdown are always on top" do
      data = { "thumbsdown" => "some value", "lifter" => "some value", "thumbsup" => "some value" }
      expect(awards_sort(data).keys).to eq(%w(thumbsup thumbsdown lifter))
    end
  end

  describe "#link_to_discussions_to_resolve" do
    describe "passing only a merge request" do
      let(:merge_request) { create(:merge_request) }

      it "links just the merge request" do
        expected_path = project_merge_request_path(merge_request.project, merge_request)

        expect(link_to_discussions_to_resolve(merge_request, nil)).to include(expected_path)
      end

      it "containst the reference to the merge request" do
        expect(link_to_discussions_to_resolve(merge_request, nil)).to include(merge_request.to_reference)
      end
    end

    describe "when passing a discussion" do
      let(:diff_note) {  create(:diff_note_on_merge_request) }
      let(:merge_request) { diff_note.noteable }
      let(:discussion) { diff_note.to_discussion }

      it "links to the merge request with first note if a single discussion was passed" do
        expected_path = Gitlab::UrlBuilder.build(diff_note)

        expect(link_to_discussions_to_resolve(merge_request, discussion)).to include(expected_path)
      end

      it "contains both the reference to the merge request and a mention of the discussion" do
        expect(link_to_discussions_to_resolve(merge_request, discussion)).to include("#{merge_request.to_reference} (discussion #{diff_note.id})")
      end
    end
  end
end
