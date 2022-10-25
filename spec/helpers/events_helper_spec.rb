# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EventsHelper do
  include Gitlab::Routing
  include Banzai::Filter::OutputSafety

  describe '#link_to_author' do
    let(:user) { create(:user) }
    let(:event) { create(:event, author: user) }

    it 'returns a link to the author' do
      name = user.name
      expect(helper.link_to_author(event)).to eq(link_to(name, user_path(user.username), title: name))
    end

    it 'returns the author name if the author is not present' do
      event.author = nil

      expect(helper.link_to_author(event)).to eq(escape_once(event.author_name))
    end

    it 'returns "You" if the author is the current user' do
      allow(helper).to receive(:current_user).and_return(user)

      name = _('You')
      expect(helper.link_to_author(event, self_added: true)).to eq(link_to(name, user_path(user.username), title: name))
    end
  end

  describe '#event_target_path' do
    subject { helper.event_target_path(event.present) }

    context 'when target is a work item' do
      let(:work_item) { create(:work_item) }
      let(:event) { create(:event, target: work_item, target_type: 'WorkItem') }

      it { is_expected.to eq(Gitlab::UrlBuilder.build(work_item, only_path: true)) }
    end

    context 'when target is not a work item' do
      let(:project) { create(:project) }
      let(:issue) { create(:issue, project: project) }
      let(:event) { create(:event, target: issue, project: project) }

      it { is_expected.to eq([project, issue]) }
    end
  end

  describe '#localized_action_name' do
    it 'handles all valid design events' do
      created, updated, destroyed = %i[created updated destroyed].map do |trait|
        event = build(:design_event, trait)
        helper.localized_action_name(event)
      end

      expect(created).to eq(_('added'))
      expect(updated).to eq(_('updated'))
      expect(destroyed).to eq(_('removed'))
    end

    context 'handles correct base actions' do
      using RSpec::Parameterized::TableSyntax

      where(:trait, :localized_action_name) do
        :created   | s_('Event|created')
        :updated   | s_('Event|opened')
        :closed    | s_('Event|closed')
        :reopened  | s_('Event|opened')
        :commented | s_('Event|commented on')
        :merged    | s_('Event|accepted')
        :joined    | s_('Event|joined')
        :left      | s_('Event|left')
        :destroyed | s_('Event|destroyed')
        :expired | s_('Event|removed due to membership expiration from')
        :approved | s_('Event|approved')
      end

      with_them do
        it 'with correct name and method' do
          event = build(:event, trait)

          expect(helper.localized_action_name(event)).to eq(localized_action_name)
        end
      end
    end
  end

  describe '#event_commit_title' do
    let(:message) { 'foo & bar ' + 'A' * 70 + '\n' + 'B' * 80 }

    subject { helper.event_commit_title(message) }

    it 'returns the first line, truncated to 70 chars' do
      is_expected.to eq(message[0..66] + "...")
    end

    it 'is not html-safe' do
      is_expected.not_to be_a(ActiveSupport::SafeBuffer)
    end

    it 'handles empty strings' do
      expect(helper.event_commit_title("")).to eq("")
    end

    it 'handles nil values' do
      expect(helper.event_commit_title(nil)).to eq('')
    end

    it 'does not escape HTML entities' do
      expect(helper.event_commit_title('foo & bar')).to eq('foo & bar')
    end
  end

  describe '#event_feed_url' do
    let(:event) { create(:event).present }
    let(:project) { create(:project, :public, :repository) }

    context 'issue' do
      before do
        event.target = create(:issue)
      end

      it 'returns the project issue url' do
        expect(helper.event_feed_url(event)).to eq(project_issue_url(event.project, event.target))
      end

      it 'contains the project issue IID link' do
        expect(helper.event_feed_title(event)).to include("##{event.target.iid}")
      end
    end

    context 'merge request' do
      before do
        event.target = create(:merge_request)
      end

      it 'returns the project merge request url' do
        expect(helper.event_feed_url(event)).to eq(project_merge_request_url(event.project, event.target))
      end

      it 'contains the project merge request IID link' do
        expect(helper.event_feed_title(event)).to include("!#{event.target.iid}")
      end
    end

    it 'returns project commit url' do
      event.target = create(:note_on_commit, project: project)

      expect(helper.event_feed_url(event)).to eq(project_commit_url(event.project, event.note_target))
    end

    it 'returns event note target url' do
      event.target = create(:note)

      expect(helper.event_feed_url(event)).to eq(event_note_target_url(event))
    end

    it 'returns project url' do
      event.project = project
      event.action = 1

      expect(helper.event_feed_url(event)).to eq(project_url(event.project))
    end

    it 'returns push event feed url' do
      event = create(:push_event)
      create(:push_event_payload, event: event, action: :pushed)

      expect(helper.event_feed_url(event)).to eq(push_event_feed_url(event))
    end

    it 'returns nil for push event with multiple refs' do
      event = create(:push_event)
      create(:push_event_payload, event: event, ref_count: 2, ref: nil, ref_type: :tag, commit_count: 0, action: :pushed)

      expect(helper.event_feed_url(event)).to eq(nil)
    end
  end

  describe '#event_preposition' do
    context 'for wiki page events' do
      let(:event) { create(:wiki_page_event) }

      it 'returns a suitable phrase' do
        expect(helper.event_preposition(event)).to eq('in the wiki for')
      end
    end

    context 'for push action events' do
      let(:event) { create(:push_event) }

      it 'returns a suitable phrase' do
        expect(helper.event_preposition(event)).to eq('at')
      end
    end

    context 'for commented actions' do
      let(:event) { create(:event, :commented) }

      it 'returns a suitable phrase' do
        expect(helper.event_preposition(event)).to eq('at')
      end
    end

    context 'for any event with a target' do
      let(:event) { create(:event, target: create(:issue)) }

      it 'returns a suitable phrase' do
        expect(helper.event_preposition(event)).to eq('at')
      end
    end

    context 'for milestone events' do
      let(:event) { create(:event, target: create(:milestone)) }

      it 'returns a suitable phrase' do
        expect(helper.event_preposition(event)).to eq('in')
      end
    end

    context 'for non-matching events' do
      let(:event) { create(:event, :created) }

      it 'returns no preposition' do
        expect(helper.event_preposition(event)).to be_nil
      end
    end
  end

  describe 'event_wiki_page_target_url' do
    let(:project) { create(:project) }
    let(:wiki_page) { create(:wiki_page, wiki: create(:project_wiki, project: project)) }
    let(:event) { create(:wiki_page_event, project: project, wiki_page: wiki_page) }

    it 'links to the wiki page' do
      url = helper.project_wiki_url(project, wiki_page.slug)

      expect(helper.event_wiki_page_target_url(event)).to eq(url)
    end

    context 'there is no canonical slug' do
      let(:event) { create(:wiki_page_event, project: project) }

      before do
        event.target.slugs.update_all(canonical: false)
        event.target.clear_memoization(:canonical_slug)
      end

      it 'links to the home page' do
        url = helper.project_wiki_url(project, Wiki::HOMEPAGE)

        expect(helper.event_wiki_page_target_url(event)).to eq(url)
      end
    end
  end

  describe '#event_wiki_title_html' do
    let(:event) { create(:wiki_page_event) }

    it 'produces a suitable title chunk' do
      url = helper.event_wiki_page_target_url(event)
      title = event.target_title
      html = [
        "<span class=\"event-target-type gl-mr-2\">wiki page</span>",
        "<a title=\"#{title}\" class=\"has-tooltip event-target-link gl-mr-2\" href=\"#{url}\">",
        title,
        "</a>"
      ].join

      expect(helper.event_wiki_title_html(event)).to eq(html)
    end
  end

  describe '#event_note_target_url' do
    let(:project) { create(:project, :public, :repository) }
    let(:event) { create(:event, project: project) }
    let(:project_base_url) { namespace_project_url(namespace_id: project.namespace, id: project) }

    subject { helper.event_note_target_url(event) }

    it 'returns a commit note url' do
      event.target = create(:note_on_commit, note: '+1 from me')

      expect(subject).to eq("#{project_base_url}/-/commit/#{event.target.commit_id}#note_#{event.target.id}")
    end

    it 'returns a project snippet note url' do
      event.target = create(:note_on_project_snippet, note: 'keep going')

      expect(subject).to eq("#{project_snippet_url(event.note_target.project, event.note_target)}#note_#{event.target.id}")
    end

    it 'returns a personal snippet note url' do
      event.target = create(:note_on_personal_snippet, note: 'keep going')

      expect(subject).to eq("#{snippet_url(event.note_target)}#note_#{event.target.id}")
    end

    it 'returns a project issue url' do
      event.target = create(:note_on_issue, note: 'nice work')

      expect(subject).to eq("#{project_base_url}/-/issues/#{event.note_target.iid}#note_#{event.target.id}")
    end

    it 'returns a merge request url' do
      event.target = create(:note_on_merge_request, note: 'LGTM!')

      expect(subject).to eq("#{project_base_url}/-/merge_requests/#{event.note_target.iid}#note_#{event.target.id}")
    end

    context 'for design note events' do
      let(:event) { create(:event, :for_design, project: project) }

      it 'returns an appropriate URL' do
        iid = event.note_target.issue.iid
        filename = event.note_target.filename
        note_id  = event.target.id

        expect(subject).to eq("#{project_base_url}/-/issues/#{iid}/designs/#{filename}#note_#{note_id}")
      end
    end
  end

  describe '#event_filter_visible' do
    include DesignManagementTestHelpers

    let_it_be(:project) { create(:project) }
    let_it_be(:current_user) { create(:user) }

    subject { helper.event_filter_visible(key) }

    before do
      enable_design_management
      project.add_reporter(current_user)
      allow(helper).to receive(:current_user).and_return(current_user)
    end

    def disable_read_design_activity(object)
      allow(Ability).to receive(:allowed?)
        .with(current_user, :read_design_activity, eq(object))
        .and_return(false)
    end

    context 'for :designs' do
      let(:key) { :designs }

      context 'there is no relevant instance variable' do
        it { is_expected.to be(true) }
      end

      context 'a project has been assigned' do
        before do
          assign(:project, project)
        end

        it { is_expected.to be(true) }

        context 'the current user cannot read design activity' do
          before do
            disable_read_design_activity(project)
          end

          it { is_expected.to be(false) }
        end
      end

      context 'projects have been assigned' do
        before do
          assign(:projects, Project.where(id: project.id))
        end

        it { is_expected.to be(true) }

        context 'the collection is empty' do
          before do
            assign(:projects, Project.none)
          end

          it { is_expected.to be(false) }
        end

        context 'the current user cannot read design activity' do
          before do
            disable_read_design_activity(project)
          end

          it { is_expected.to be(false) }
        end
      end

      context 'a group has been assigned' do
        let_it_be(:group) { create(:group) }

        before do
          assign(:group, group)
        end

        context 'there are no projects in the group' do
          it { is_expected.to be(false) }
        end

        context 'the group has at least one project' do
          before do
            create(:project_group_link, project: project, group: group)
          end

          it { is_expected.to be(true) }

          context 'the current user cannot read design activity' do
            before do
              disable_read_design_activity(group)
            end

            it { is_expected.to be(false) }
          end
        end
      end
    end
  end
end
