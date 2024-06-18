# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::IssuesHelper, feature_category: :team_planning do
  describe '#create_mr_tracking_data' do
    using RSpec::Parameterized::TableSyntax

    where(:can_create_mr, :can_create_confidential_mr, :tracking_data) do
      true  | true  | { event_tracking: 'click_create_confidential_mr_issues_list' }
      true  | false | { event_tracking: 'click_create_mr_issues_list' }
      false | false | {}
    end

    with_them do
      it do
        expect(create_mr_tracking_data(can_create_mr, can_create_confidential_mr)).to eq(tracking_data)
      end
    end
  end
end
