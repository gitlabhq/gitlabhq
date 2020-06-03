# frozen_string_literal: true

require "spec_helper"

describe IssuesHelper do
  let(:project) { create(:project) }
  let(:issue) { create :issue, project: project }
  let(:ext_project) { create :redmine_project }

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
    let(:awardable) { upvote.awardable }
    let(:user) { upvote.user }

    before do
      allow(helper).to receive(:can?) do |*args|
        Ability.allowed?(*args)
      end
    end

    it "returns disabled string for unauthenticated user" do
      expect(helper.award_state_class(awardable, AwardEmoji.all, nil)).to eq("disabled")
    end

    it "returns disabled for a user that does not have access to the awardable" do
      expect(helper.award_state_class(awardable, AwardEmoji.all, build(:user))).to eq("disabled")
    end

    it "returns active string for author" do
      expect(helper.award_state_class(awardable, AwardEmoji.all, upvote.user)).to eq("active")
    end

    it "is blank for a user that has access to the awardable" do
      user = build(:user)
      expect(helper).to receive(:can?).with(user, :award_emoji, awardable).and_return(true)

      expect(helper.award_state_class(awardable, AwardEmoji.all, user)).to be_blank
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

      it "contains the reference to the merge request" do
        expect(link_to_discussions_to_resolve(merge_request, nil)).to include(merge_request.to_reference)
      end
    end

    describe "when passing a discussion" do
      let(:diff_note) { create(:diff_note_on_merge_request) }
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

  describe '#show_new_issue_link?' do
    before do
      allow(helper).to receive(:current_user)
    end

    it 'is false when no project there is no project' do
      expect(helper.show_new_issue_link?(nil)).to be_falsey
    end

    it 'is true when there is a project and no logged in user' do
      expect(helper.show_new_issue_link?(build(:project))).to be_truthy
    end

    it 'is true when the current user does not have access to the project' do
      project = build(:project)
      allow(helper).to receive(:current_user).and_return(project.owner)

      expect(helper).to receive(:can?).with(project.owner, :create_issue, project).and_return(true)
      expect(helper.show_new_issue_link?(project)).to be_truthy
    end
  end

  describe '#issue_closed_link' do
    let(:new_issue) { create(:issue, project: project) }
    let(:guest)     { create(:user) }

    before do
      allow(helper).to receive(:can?) do |*args|
        Ability.allowed?(*args)
      end
    end

    shared_examples 'successfully displays link to issue and with css class' do |action|
      it 'returns link' do
        link = "<a class=\"#{css_class}\" href=\"/#{new_issue.project.full_path}/-/issues/#{new_issue.iid}\">(#{action})</a>"

        expect(helper.issue_closed_link(issue, user, css_class: css_class)).to match(link)
      end
    end

    shared_examples 'does not display link' do
      it 'returns nil' do
        expect(helper.issue_closed_link(issue, user)).to be_nil
      end
    end

    context 'with linked issue' do
      context 'with moved issue' do
        before do
          issue.update(moved_to: new_issue)
        end

        context 'when user has permission to see new issue' do
          let(:user)      { project.owner }
          let(:css_class) { 'text-white text-underline' }

          it_behaves_like 'successfully displays link to issue and with css class', 'moved'
        end

        context 'when user has no permission to see new issue' do
          let(:user) { guest }

          it_behaves_like 'does not display link'
        end
      end

      context 'with duplicated issue' do
        before do
          issue.update(duplicated_to: new_issue)
        end

        context 'when user has permission to see new issue' do
          let(:user)      { project.owner }
          let(:css_class) { 'text-white text-underline' }

          it_behaves_like 'successfully displays link to issue and with css class', 'duplicated'
        end

        context 'when user has no permission to see new issue' do
          let(:user) { guest }

          it_behaves_like 'does not display link'
        end
      end
    end

    context 'without linked issue' do
      let(:user) { project.owner }

      before do
        issue.update(moved_to: nil, duplicated_to: nil)
      end

      it_behaves_like 'does not display link'
    end
  end
end
