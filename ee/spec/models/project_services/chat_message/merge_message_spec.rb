require 'spec_helper'

RSpec.describe ChatMessage::MergeMessage do
  subject { described_class.new(args) }

  let(:args) do
    {
      user: {
          name: 'Test User',
          username: 'test.user',
          avatar_url: 'http://someavatar.com'
      },
      project_name: 'project_name',
      project_url: 'http://somewhere.com',

      object_attributes: {
        title: "Merge Request title\nSecond line",
        id: 10,
        iid: 100,
        assignee_id: 1,
        url: 'http://url.com',
        state: 'opened',
        description: 'merge request description',
        source_branch: 'source_branch',
        target_branch: 'target_branch'
      }
    }
  end

  context 'approval' do
    before do
      args[:object_attributes][:action] = 'approved'
    end

    it 'returns a message regarding approval of merge requests' do
      expect(subject.pretext).to eq(
        'Test User (test.user) approved <http://somewhere.com/merge_requests/100|!100 *Merge Request title*> '\
        'in <http://somewhere.com|project_name>')
      expect(subject.attachments).to be_empty
    end
  end
end
