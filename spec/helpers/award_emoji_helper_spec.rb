require 'spec_helper'

describe AwardEmojiHelper do
  describe '.toggle_award_url' do
    context 'note on personal snippet' do
      let(:note) { create(:note_on_personal_snippet) }

      it 'returns correct url' do
        expected_url = "/snippets/#{note.noteable.id}/notes/#{note.id}/toggle_award_emoji"

        expect(helper.toggle_award_url(note)).to eq(expected_url)
      end
    end

    context 'note on project item' do
      let(:note) { create(:note_on_project_snippet) }

      it 'returns correct url' do
        @project = note.noteable.project

        expected_url = "/#{@project.namespace.path}/#{@project.path}/notes/#{note.id}/toggle_award_emoji"

        expect(helper.toggle_award_url(note)).to eq(expected_url)
      end
    end

    context 'personal snippet' do
      let(:snippet) { create(:personal_snippet) }

      it 'returns correct url' do
        expected_url = "/snippets/#{snippet.id}/toggle_award_emoji"

        expect(helper.toggle_award_url(snippet)).to eq(expected_url)
      end
    end

    context 'merge request' do
      let(:merge_request) { create(:merge_request) }

      it 'returns correct url' do
        @project = merge_request.project

        expected_url = "/#{@project.namespace.path}/#{@project.path}/merge_requests/#{merge_request.iid}/toggle_award_emoji"

        expect(helper.toggle_award_url(merge_request)).to eq(expected_url)
      end
    end

    context 'issue' do
      let(:issue) { create(:issue) }

      it 'returns correct url' do
        @project = issue.project

        expected_url = "/#{@project.namespace.path}/#{@project.path}/issues/#{issue.iid}/toggle_award_emoji"

        expect(helper.toggle_award_url(issue)).to eq(expected_url)
      end
    end
  end
end
