# frozen_string_literal: true

require 'spec_helper'

describe EventsHelper do
  include Gitlab::Routing

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
        "<span class=\"event-target-type append-right-4\">wiki page</span>",
        "<a title=\"#{title}\" class=\"has-tooltip event-target-link append-right-4\" href=\"#{url}\">",
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

      expect(subject).to eq("#{project_base_url}/snippets/#{event.note_target.id}#note_#{event.target.id}")
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
end
