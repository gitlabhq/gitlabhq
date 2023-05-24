# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ResourceEvents::AbuseReportEventsHelper, feature_category: :instance_resiliency do
  describe '#success_message_for_action' do
    using RSpec::Parameterized::TableSyntax

    where(:action, :action_value) do
      ResourceEvents::AbuseReportEvent.actions.to_a
    end

    with_them do
      it { expect(helper.success_message_for_action(action)).not_to be_nil }
    end
  end
end
