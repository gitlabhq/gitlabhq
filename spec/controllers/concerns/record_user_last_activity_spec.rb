# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RecordUserLastActivity, feature_category: :seat_cost_management do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:user) { create(:user) }

  let(:controller_class) do
    # rubocop:disable Rails/ApplicationController -- This is a test controller
    Class.new(ActionController::Base) do
      include RecordUserLastActivity

      def initialize(user, group, project)
        @current_user = user
        @group = group
        @project = project
      end

      def request
        @request ||= Struct.new(:get?, :env).new(true, { 'HTTP_CF_IPCOUNTRY' => 'US' })
      end
    end
    # rubocop:enable Rails/ApplicationController
  end

  subject(:controller) { controller_class.new(user, group, project) }

  shared_examples 'does not update the user activity timestamp' do
    it 'does not update the user last activity' do
      expect { controller.set_user_last_activity }.not_to change { user.reload.last_activity_on }
    end
  end

  describe '#set_user_last_activity' do
    context 'when the request is a GET request' do
      it 'updates the user last activity' do
        expect { controller.set_user_last_activity }.to change { user.reload.last_activity_on }
      end
    end

    context 'when the request is not a GET request' do
      before do
        allow(controller.request).to receive(:get?).and_return(false)
      end

      it_behaves_like 'does not update the user activity timestamp'
    end

    context 'when the database is read-only' do
      before do
        allow(Gitlab::Database).to receive(:read_only?).and_return(true)
      end

      it_behaves_like 'does not update the user activity timestamp'
    end

    context 'when there is no current user' do
      before do
        allow(controller).to receive(:current_user).and_return(nil)
      end

      it_behaves_like 'does not update the user activity timestamp'
    end
  end

  describe '#set_member_last_activity' do
    shared_examples 'does not update publish an activity event' do
      it do
        expect { controller.set_member_last_activity }.not_to publish_event(Users::ActivityEvent)
      end
    end

    shared_examples 'publishes an activity event' do
      it 'publishes a Users::ActivityEvent' do
        expect { controller.set_member_last_activity }
          .to publish_event(Users::ActivityEvent)
          .with({
            user_id: user.id,
            namespace_id: context.root_ancestor.id
          })
      end
    end

    context 'when the request is a GET request' do
      context 'when a group is available' do
        let(:context) { group }

        it_behaves_like 'publishes an activity event'
      end

      context 'when no group is available' do
        let(:group) { nil }

        context 'when a project is available' do
          let(:context) { project }

          it_behaves_like 'publishes an activity event'
        end
      end

      context 'when there is no group or project' do
        let(:group) { nil }
        let(:project) { nil }

        it_behaves_like 'does not update publish an activity event'
      end
    end

    context 'when the request is not a GET request' do
      before do
        allow(controller.request).to receive(:get?).and_return(false)
      end

      it_behaves_like 'does not update publish an activity event'
    end
  end
end
