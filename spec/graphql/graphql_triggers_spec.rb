# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GraphqlTriggers, feature_category: :shared do
  let_it_be(:project) { create(:project) }
  let_it_be(:issuable, refind: true) { create(:work_item, project: project) }

  describe '.issuable_assignees_updated' do
    let(:assignees) { create_list(:user, 2) }

    before do
      issuable.update!(assignees: assignees)
    end

    it 'triggers the issuable_assignees_updated subscription' do
      expect(GitlabSchema.subscriptions).to receive(:trigger).with(
        :issuable_assignees_updated,
        { issuable_id: issuable.to_gid },
        issuable
      )

      described_class.issuable_assignees_updated(issuable)
    end
  end

  describe '.issuable_title_updated' do
    it 'triggers the issuable_title_updated subscription' do
      expect(GitlabSchema.subscriptions).to receive(:trigger).with(
        :issuable_title_updated,
        { issuable_id: issuable.to_gid },
        issuable
      ).and_call_original

      described_class.issuable_title_updated(issuable)
    end
  end

  describe '.issuable_description_updated' do
    it 'triggers the issuable_description_updated subscription' do
      expect(GitlabSchema.subscriptions).to receive(:trigger).with(
        :issuable_description_updated,
        { issuable_id: issuable.to_gid },
        issuable
      ).and_call_original

      described_class.issuable_description_updated(issuable)
    end
  end

  describe '.issuable_labels_updated' do
    let(:labels) { create_list(:label, 3, project: create(:project)) }

    before do
      issuable.update!(labels: labels)
    end

    it 'triggers the issuable_labels_updated subscription' do
      expect(GitlabSchema.subscriptions).to receive(:trigger).with(
        :issuable_labels_updated,
        { issuable_id: issuable.to_gid },
        issuable
      )

      described_class.issuable_labels_updated(issuable)
    end
  end

  describe '.issuable_dates_updated' do
    it 'triggers the issuable_dates_updated subscription' do
      expect(GitlabSchema.subscriptions).to receive(:trigger).with(
        :issuable_dates_updated,
        { issuable_id: issuable.to_gid },
        issuable
      ).and_call_original

      described_class.issuable_dates_updated(issuable)
    end
  end

  describe '.issuable_milestone_updated' do
    it 'triggers the issuable_milestone_updated subscription' do
      expect(GitlabSchema.subscriptions).to receive(:trigger).with(
        :issuable_milestone_updated,
        { issuable_id: issuable.to_gid },
        issuable
      ).and_call_original

      described_class.issuable_milestone_updated(issuable)
    end
  end

  describe '.merge_request_reviewers_updated' do
    it 'triggers the merge_request_reviewers_updated subscription' do
      merge_request = build_stubbed(:merge_request)

      expect(GitlabSchema.subscriptions).to receive(:trigger).with(
        :merge_request_reviewers_updated,
        { issuable_id: merge_request.to_gid },
        merge_request
      ).and_call_original

      described_class.merge_request_reviewers_updated(merge_request)
    end
  end

  describe '.merge_request_merge_status_updated' do
    it 'triggers the merge_request_merge_status_updated subscription' do
      merge_request = build_stubbed(:merge_request)

      expect(GitlabSchema.subscriptions).to receive(:trigger).with(
        :merge_request_merge_status_updated,
        { issuable_id: merge_request.to_gid },
        merge_request
      ).and_call_original

      described_class.merge_request_merge_status_updated(merge_request)
    end
  end

  describe '.merge_request_approval_state_updated' do
    it 'triggers the merge_request_approval_state_updated subscription' do
      merge_request = build_stubbed(:merge_request)

      expect(GitlabSchema.subscriptions).to receive(:trigger).with(
        :merge_request_approval_state_updated,
        { issuable_id: merge_request.to_gid },
        merge_request
      ).and_call_original

      described_class.merge_request_approval_state_updated(merge_request)
    end
  end

  describe '.merge_request_diff_generated' do
    it 'triggers the merge_request_diff_generated subscription' do
      merge_request = build_stubbed(:merge_request)

      expect(GitlabSchema.subscriptions).to receive(:trigger).with(
        :merge_request_diff_generated,
        { issuable_id: merge_request.to_gid },
        merge_request
      ).and_call_original

      described_class.merge_request_diff_generated(merge_request)
    end
  end

  describe '.work_item_updated' do
    it 'triggers the work_item_updated subscription' do
      expect(GitlabSchema.subscriptions).to receive(:trigger).with(
        'workItemUpdated',
        { work_item_id: issuable.to_gid },
        issuable
      ).and_call_original

      described_class.work_item_updated(issuable)
    end

    context 'when triggered with an Issue' do
      it 'triggers the subscription with a work item' do
        issue = create(:issue, project: project)
        work_item = WorkItem.find(issue.id)

        expect(GitlabSchema.subscriptions).to receive(:trigger).with(
          'workItemUpdated',
          { work_item_id: work_item.to_gid },
          work_item
        ).and_call_original

        described_class.work_item_updated(issue)
      end
    end
  end

  describe '.issuable_todo_updated' do
    let_it_be(:user) { create(:user) }

    it 'triggers the issuable_todo_updated subscription' do
      expect(GitlabSchema.subscriptions).to receive(:trigger).with(
        :issuable_todo_updated,
        { issuable_id: issuable.to_gid },
        issuable
      ).and_call_original

      described_class.issuable_todo_updated(issuable)
    end
  end

  describe '.user_merge_request_updated' do
    let_it_be(:user) { create(:user) }
    let_it_be(:merge_request) { create(:merge_request) }

    it 'triggers the user_merge_request_updated subscription' do
      expect(GitlabSchema.subscriptions).to receive(:trigger).with(
        :user_merge_request_updated,
        { user_id: user.to_gid },
        merge_request
      ).and_call_original

      described_class.user_merge_request_updated(user, merge_request)
    end
  end

  describe '.ci_pipeline_status_updated' do
    let_it_be(:pipeline) { create(:ci_pipeline) }
    let_it_be(:user) { pipeline.project.owners.first }

    it 'triggers the ci_pipeline_status_updated subscription' do
      expect(GitlabSchema.subscriptions).to receive(:trigger).with(
        :ci_pipeline_status_updated,
        { pipeline_id: pipeline.to_gid },
        pipeline
      ).and_call_original

      described_class.ci_pipeline_status_updated(pipeline)
    end
  end

  describe '.ci_pipeline_job_updated' do
    let_it_be(:job) { create(:ci_build) }

    it 'triggers the ci_job_status_updated subscription' do
      expect(GitlabSchema.subscriptions).to receive(:trigger).with(
        :ci_job_status_updated,
        { job_id: job.to_gid },
        job
      )

      described_class.ci_job_status_updated(job)
    end
  end

  describe '.ci_pipeline_schedule_status_updated' do
    let_it_be(:schedule) { create(:ci_pipeline_schedule, project: project, owner: project.first_owner) }

    it 'triggers the ci_pipeline_schedule_status_updated subscription' do
      expect(GitlabSchema.subscriptions).to receive(:trigger).with(
        :ci_pipeline_schedule_status_updated,
        { project_id: schedule.project.to_gid },
        schedule
      )

      described_class.ci_pipeline_schedule_status_updated(schedule)
    end
  end

  describe '.ci_pipeline_creation_requests_updated' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

    it 'triggers the ci_pipeline_creation_requests_updated subscription' do
      expect(GitlabSchema.subscriptions).to receive(:trigger).with(
        :ci_pipeline_creation_requests_updated,
        { merge_request_id: merge_request.to_gid },
        merge_request
      ).and_call_original

      described_class.ci_pipeline_creation_requests_updated(merge_request)
    end

    describe 'when FF ci_pipeline_creation_requests_realtime is disabled' do
      before do
        stub_feature_flags(ci_pipeline_creation_requests_realtime: false)
      end

      it 'does not trigger the subscription' do
        expect(GitlabSchema.subscriptions).not_to receive(:trigger).with(
          :ci_pipeline_creation_requests_updated,
          { merge_request_id: merge_request.to_gid },
          merge_request
        )

        described_class.ci_pipeline_creation_requests_updated(merge_request)
      end
    end

    it 'passes correct merge request GID to subscription' do
      expected_gid = merge_request.to_gid

      expect(GitlabSchema.subscriptions).to receive(:trigger) do |subscription_name, args|
        expect(subscription_name).to eq(:ci_pipeline_creation_requests_updated)
        expect(args[:merge_request_id]).to eq(expected_gid)
        expect(args[:merge_request_id]).to be_a(GlobalID)
        expect(args[:merge_request_id].model_class).to eq(MergeRequest)
      end

      described_class.ci_pipeline_creation_requests_updated(merge_request)
    end
  end

  describe '.ci_job_processed' do
    let_it_be(:job) { create(:ci_build) }

    it 'triggers the ci_job_processed subscription' do
      expect(GitlabSchema.subscriptions).to receive(:trigger).with(
        :ci_job_processed,
        { project_id: job.project.to_gid },
        job
      )

      described_class.ci_job_processed(job)
    end

    it 'triggers the ci_job_processed_with_artifacts subscription with additional arguments' do
      expect(GitlabSchema.subscriptions).to receive(:trigger).with(
        :ci_job_processed,
        { project_id: job.project.to_gid, with_artifacts: true },
        job
      )

      described_class.ci_job_processed_with_artifacts(job)
    end

    describe 'when ci_job_created_subscription is disabled' do
      before do
        stub_feature_flags(ci_job_created_subscription: false)
      end

      it 'does not trigger the ci_job_processed subscription' do
        expect(GitlabSchema.subscriptions).not_to receive(:trigger).with(
          :ci_job_processed,
          { project_id: job.project.to_gid },
          job
        )

        described_class.ci_job_processed(job)
      end

      it 'does not trigger the ci_job_processed subscription with additional arguments' do
        expect(GitlabSchema.subscriptions).not_to receive(:trigger).with(
          :ci_job_processed,
          { project_id: job.project.to_gid, with_artifacts: true },
          job
        )

        described_class.ci_job_processed_with_artifacts(job)
      end
    end
  end
end
