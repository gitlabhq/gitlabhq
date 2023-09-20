# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::TriggersFinder, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:trigger) { create(:ci_trigger, project: project) }

  subject { described_class.new(current_user, project).execute }

  describe "#execute" do
    context 'when the current user is authorized' do
      before_all do
        project.add_owner(current_user)
      end

      it 'returns list of trigger tokens' do
        expect(subject).to contain_exactly(trigger)
      end
    end

    context 'when the current user is not authorized' do
      it 'does not return trigger tokens' do
        expect(subject).to be_blank
      end
    end
  end
end
