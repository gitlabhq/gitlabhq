# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssuableActions do
  let(:project) { double('project') }
  let(:user) { double('user') }
  let(:issuable) { double('issuable') }
  let(:finder_params_for_issuable) { { project: project, target: issuable } }
  let(:notes_result) { [] }
  let(:discussion_serializer) { double('discussion_serializer') }

  let(:controller) do
    klass = Class.new do
      attr_reader :current_user, :project, :issuable

      def self.before_action(action = nil, params = nil); end

      include IssuableActions

      def initialize(issuable, project, user, finder_params)
        @issuable = issuable
        @project = project
        @current_user = user
        @finder_params = finder_params
      end

      def finder_params_for_issuable
        @finder_params
      end

      def params
        {
          notes_filter: 1
        }
      end

      def prepare_notes_for_rendering(notes)
        []
      end

      def render(options); end
    end

    klass.new(issuable, project, user, finder_params_for_issuable)
  end

  describe '#discussions' do
    before do
      allow(user).to receive(:set_notes_filter)
      allow(user).to receive(:user_preference)
      allow(discussion_serializer).to receive(:represent)
    end

    it 'instantiates and calls NotesFinder as expected' do
      expect(issuable).to receive(:to_ability_name).and_return('issue')
      expect(issuable).to receive(:project).and_return(project)
      expect(Ability).to receive(:allowed?).at_least(1).and_return(true)
      expect(Discussion).to receive(:build_collection).and_return([])
      expect(DiscussionSerializer).to receive(:new).and_return(discussion_serializer)
      expect(NotesFinder).to receive(:new).with(user, finder_params_for_issuable).and_call_original

      expect_any_instance_of(NotesFinder).to receive(:execute).and_return(notes_result)

      expect(notes_result).to receive_messages(
        with_web_entity_associations: notes_result,
        inc_relations_for_view: notes_result,
        fresh: notes_result
      )

      controller.discussions
    end
  end
end
