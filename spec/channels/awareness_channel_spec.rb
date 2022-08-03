# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AwarenessChannel, :clean_gitlab_redis_shared_state, type: :channel do
  before do
    stub_action_cable_connection(current_user: user)
  end

  context "with user" do
    let(:user) { create(:user) }

    describe "when no path parameter given" do
      it "rejects subscription" do
        subscribe path: nil

        expect(subscription).to be_rejected
      end
    end

    describe "with valid path parameter" do
      it "successfully subscribes" do
        subscribe path: "/test"

        session = AwarenessSession.for("/test")

        expect(subscription).to be_confirmed
        # check if we can use session object instead
        expect(subscription).to have_stream_from("awareness:#{session.to_param}")
      end

      it "broadcasts set of collaborators when subscribing" do
        session = AwarenessSession.for("/test")

        freeze_time do
          collaborator = {
            id: user.id,
            name: user.name,
            username: user.username,
            avatar_url: user.avatar_url(size: 36),
            last_activity: Time.zone.now,
            last_activity_humanized: ActionController::Base.helpers.distance_of_time_in_words(
              Time.zone.now, Time.zone.now
            )
          }

          expect do
            subscribe path: "/test"
          end.to have_broadcasted_to("awareness:#{session.to_param}")
                   .with(collaborators: [collaborator])
        end
      end

      it "transmits payload when user is touched" do
        subscribe path: "/test"

        perform :touch

        expect(transmissions.size).to be 1
      end

      it "unsubscribes from channel" do
        subscribe path: "/test"
        session = AwarenessSession.for("/test")

        expect { subscription.unsubscribe_from_channel }
          .to change { session.size}.by(-1)
      end
    end
  end

  context "with guest" do
    let(:user) { nil }

    it "rejects subscription" do
      subscribe path: "/test"

      expect(subscription).to be_rejected
    end
  end
end
