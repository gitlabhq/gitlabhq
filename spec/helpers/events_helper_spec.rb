# frozen_string_literal: true

require 'spec_helper'

describe EventsHelper do
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

  describe '#event_note_target_url' do
    let(:project) { create(:project, :public, :repository) }
    let(:event) { create(:event, project: project) }
    let(:project_base_url) { namespace_project_url(namespace_id: project.namespace, id: project) }

    subject { helper.event_note_target_url(event) }

    it 'returns a commit note url' do
      event.target = create(:note_on_commit, note: '+1 from me')

      expect(subject).to eq("#{project_base_url}/commit/#{event.target.commit_id}#note_#{event.target.id}")
    end

    it 'returns a project snippet note url' do
      event.target = create(:note, :on_snippet, note: 'keep going')

      expect(subject).to eq("#{project_base_url}/snippets/#{event.note_target.id}#note_#{event.target.id}")
    end

    it 'returns a project issue url' do
      event.target = create(:note_on_issue, note: 'nice work')

      expect(subject).to eq("#{project_base_url}/issues/#{event.note_target.iid}#note_#{event.target.id}")
    end

    it 'returns a merge request url' do
      event.target = create(:note_on_merge_request, note: 'LGTM!')

      expect(subject).to eq("#{project_base_url}/merge_requests/#{event.note_target.iid}#note_#{event.target.id}")
    end
  end
end
