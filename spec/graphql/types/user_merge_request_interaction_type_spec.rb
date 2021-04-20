# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['UserMergeRequestInteraction'] do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }

  let(:interaction) { ::Users::MergeRequestInteraction.new(user: user, merge_request: merge_request.reset) }

  specify { expect(described_class).to require_graphql_authorizations(:read_merge_request) }

  it 'has the expected fields' do
    expected_fields = %w[
      can_merge
      can_update
      review_state
      reviewed
      approved
    ]

    expect(described_class).to have_graphql_fields(*expected_fields).at_least
  end

  def resolve(field_name)
    resolve_field(field_name, interaction, current_user: current_user)
  end

  describe '#can_merge' do
    subject { resolve(:can_merge) }

    context 'when the user cannot merge' do
      it { is_expected.to be false }
    end

    context 'when the user can merge' do
      before do
        project.add_maintainer(user)
      end

      it { is_expected.to be true }
    end
  end

  describe '#can_update' do
    subject { resolve(:can_update) }

    context 'when the user cannot update the MR' do
      it { is_expected.to be false }
    end

    context 'when the user can update the MR' do
      before do
        project.add_developer(user)
      end

      it { is_expected.to be true }
    end
  end

  describe '#review_state' do
    subject { resolve(:review_state) }

    context 'when the user has not been asked to review the MR' do
      it { is_expected.to be_nil }

      it 'implies not reviewed' do
        expect(resolve(:reviewed)).to be false
      end
    end

    context 'when the user has been asked to review the MR' do
      before do
        merge_request.reviewers << user
      end

      it { is_expected.to eq(Types::MergeRequestReviewStateEnum.values['UNREVIEWED'].value) }

      it 'implies not reviewed' do
        expect(resolve(:reviewed)).to be false
      end
    end

    context 'when the user has provided a review' do
      before do
        merge_request.merge_request_reviewers.create!(reviewer: user, state: MergeRequestReviewer.states['reviewed'])
      end

      it { is_expected.to eq(Types::MergeRequestReviewStateEnum.values['REVIEWED'].value) }

      it 'implies reviewed' do
        expect(resolve(:reviewed)).to be true
      end
    end
  end

  describe '#approved' do
    subject { resolve(:approved) }

    context 'when the user has not approved the MR' do
      it { is_expected.to be false }
    end

    context 'when the user has approved the MR' do
      before do
        merge_request.approved_by_users << user
      end

      it { is_expected.to be true }
    end
  end
end
