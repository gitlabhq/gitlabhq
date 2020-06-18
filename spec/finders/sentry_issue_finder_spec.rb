# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SentryIssueFinder do
  let(:user)          { create(:user) }
  let(:project)       { create(:project, :repository) }
  let(:issue)         { create(:issue, project: project) }
  let(:sentry_issue)  { create(:sentry_issue, issue: issue) }

  let(:finder)        { described_class.new(project, current_user: user) }

  describe '#execute' do
    let(:identifier) { sentry_issue.sentry_issue_identifier }

    subject { finder.execute(identifier) }

    context 'when the user is not part of the project' do
      it { is_expected.to be_nil }
    end

    context 'when the user is a project developer' do
      before do
        project.add_developer(user)
      end

      it { is_expected.to eq(sentry_issue) }

      context 'when identifier is incorrect' do
        let(:identifier) { non_existing_record_id }

        it { is_expected.to be_nil }
      end

      context 'when accessing another projects identifier' do
        let(:second_project) { create(:project) }
        let(:second_issue) { create(:issue, project: second_project) }
        let(:second_sentry_issue) { create(:sentry_issue, issue: second_issue) }

        let(:identifier) { second_sentry_issue.sentry_issue_identifier }

        it { is_expected.to be_nil }
      end
    end
  end
end
