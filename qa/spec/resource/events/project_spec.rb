# frozen_string_literal: true

RSpec.describe QA::Resource::Events::Project do
  let(:resource) do
    Class.new(QA::Resource::Base) do
      def api_get_path
        '/foo'
      end

      def default_branch
        'master'
      end
    end
  end

  let(:all_events) do
    [
      {
        action_name: "pushed",
        push_data: {
          commit_title: "foo commit"
        }
      },
      {
        action_name: "pushed",
        push_data: {
          ref: "master"
        }
      },
      {
        action_name: "pushed",
        push_data: {
          ref: "another-branch"
        }
      }
    ]
  end

  before do
    allow(subject).to receive_messages(max_wait: 0.01, raise_on_failure: false, parse_body: all_events)
  end

  subject { resource.tap { |f| f.include(described_class) }.new }

  describe "#wait_for_push" do
    it 'waits for a push with a specified commit message' do
      expect(subject).to receive(:api_get_from).with('/foo/events?action=pushed')
      expect { subject.wait_for_push('foo commit') }.not_to raise_error
    end

    it 'raises an error if a push with the specified commit message is not found' do
      expect(subject).to receive(:api_get_from).with('/foo/events?action=pushed').at_least(:once)
      expect { subject.wait_for_push('bar') }.to raise_error(QA::Resource::Events::EventNotFoundError)
    end
  end

  describe "#wait_for_push_new_branch" do
    it 'waits for a push to the default branch if no branch is given' do
      expect(subject).to receive(:api_get_from).with('/foo/events?action=pushed')
      expect { subject.wait_for_push_new_branch }.not_to raise_error
    end

    it 'waits for a push to the given branch' do
      expect(subject).to receive(:api_get_from).with('/foo/events?action=pushed')
      expect { subject.wait_for_push_new_branch('another-branch') }.not_to raise_error
    end

    it 'raises an error if a push with the specified branch is not found' do
      expect(subject).to receive(:api_get_from).with('/foo/events?action=pushed').at_least(:once)
      expect { subject.wait_for_push_new_branch('bar') }.to raise_error(QA::Resource::Events::EventNotFoundError)
    end
  end
end
