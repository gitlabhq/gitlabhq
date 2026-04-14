import MergeRequestStore from '~/vue_merge_request_widget/stores/mr_widget_store';
import { stateKey } from '~/vue_merge_request_widget/stores/state_maps';
import mockData, { mockPipelineSubscription } from '../mock_data';

describe('MergeRequestStore', () => {
  let store;

  beforeEach(() => {
    store = new MergeRequestStore(mockData);
  });

  it('should initialize ona attributes', () => {
    expect(store).toMatchObject({
      gitpodEnabled: mockData.gitpod_enabled,
      showGitpodButton: mockData.show_gitpod_button,
      gitpodUrl: mockData.gitpod_url,
      userPreferencesGitpodPath: mockData.user_preferences_gitpod_path,
      userProfileEnableGitpodPath: mockData.user_profile_enable_gitpod_path,
    });
  });

  describe('setData', () => {
    it('should update cached sha after rebasing', () => {
      store.setData({ ...mockData, diff_head_sha: 'abc123' }, true);

      expect(store.sha).toBe('abc123');
    });

    describe('isPipelinePassing', () => {
      it('is true when the CI status is `success`', () => {
        store.setData({ ...mockData, ci_status: 'success' });

        expect(store.isPipelinePassing).toBe(true);
      });

      it('is true when the CI status is `success-with-warnings`', () => {
        store.setData({ ...mockData, ci_status: 'success-with-warnings' });

        expect(store.isPipelinePassing).toBe(true);
      });

      it('is false when the CI status is `failed`', () => {
        store.setData({ ...mockData, ci_status: 'failed' });

        expect(store.isPipelinePassing).toBe(false);
      });

      it('is false when the CI status is anything except `success`', () => {
        store.setData({ ...mockData, ci_status: 'foobarbaz' });

        expect(store.isPipelinePassing).toBe(false);
      });
    });

    describe('isPipelineSkipped', () => {
      it('should set isPipelineSkipped=true when the CI status is `skipped`', () => {
        store.setData({ ...mockData, ci_status: 'skipped' });

        expect(store.isPipelineSkipped).toBe(true);
      });

      it('should set isPipelineSkipped=false when the CI status is anything except `skipped`', () => {
        store.setData({ ...mockData, ci_status: 'foobarbaz' });

        expect(store.isPipelineSkipped).toBe(false);
      });
    });

    describe('isPipelineBlocked', () => {
      const pipelineWaitingForManualAction = {
        details: {
          status: {
            group: 'manual',
          },
        },
      };

      it('should be `false` when the pipeline status is missing', () => {
        store.setData({ ...mockData, pipeline: undefined });

        expect(store.isPipelineBlocked).toBe(false);
      });

      it('should be `false` when the pipeline is waiting for manual action', () => {
        store.setData({ ...mockData, pipeline: pipelineWaitingForManualAction });

        expect(store.isPipelineBlocked).toBe(false);
      });

      it('should be `true` when the pipeline is waiting for manual action and the pipeline must succeed', () => {
        store.setData({
          ...mockData,
          pipeline: pipelineWaitingForManualAction,
          only_allow_merge_if_pipeline_succeeds: true,
        });

        expect(store.isPipelineBlocked).toBe(true);
      });
    });

    describe('isNothingToMergeState', () => {
      it('returns true when nothingToMerge', () => {
        store.state = stateKey.nothingToMerge;

        expect(store.isNothingToMergeState).toBe(true);
      });

      it('returns false when not nothingToMerge', () => {
        store.state = 'state';

        expect(store.isNothingToMergeState).toBe(false);
      });
    });
  });

  describe('setPaths', () => {
    it('should set the add ci config path', () => {
      store.setPaths({ ...mockData });

      expect(store.mergeRequestAddCiConfigPath).toBe('/root/group2/project2/-/ci/editor');
    });

    it('should set humanAccess=Maintainer when user has that role', () => {
      store.setPaths({ ...mockData });

      expect(store.humanAccess).toBe('Maintainer');
    });

    it('should set pipelinesEmptySvgPath', () => {
      store.setPaths({ ...mockData });

      expect(store.pipelinesEmptySvgPath).toBe('/path/to/svg');
    });

    it('should set newPipelinePath', () => {
      store.setPaths({ ...mockData });

      expect(store.newPipelinePath).toBe('/group2/project2/pipelines/new');
    });

    it('should set sourceProjectDefaultUrl', () => {
      store.setPaths({ ...mockData });

      expect(store.sourceProjectDefaultUrl).toBe('/gitlab-org/html5-boilerplate.git');
    });

    it('should set securityReportsDocsPath', () => {
      store.setPaths({ ...mockData });

      expect(store.securityReportsDocsPath).toBe('security-reports-docs-path');
    });
  });

  describe('preventMerge', () => {
    it('is false when approvals are not available', () => {
      store.hasApprovalsAvailable = false;

      expect(store.preventMerge).toBe(false);
    });

    describe('when approvals are available', () => {
      beforeEach(() => {
        store.hasApprovalsAvailable = true;
      });

      it('is true when MR is not approved', () => {
        store.setApprovals({ approved: false });

        expect(store.preventMerge).toBe(true);
      });

      it('is false when MR is approved', () => {
        store.setApprovals({ approved: true });

        expect(store.preventMerge).toBe(false);
      });
    });

    describe('setRemoveSourceBranch', () => {
      it('updates removeSourceBranch', () => {
        store.setRemoveSourceBranch(true);
        expect(store.shouldRemoveSourceBranch).toBe(true);

        store.setRemoveSourceBranch(false);
        expect(store.shouldRemoveSourceBranch).toBe(false);
      });
    });
  });

  describe('buildMetrics', () => {
    it('returns empty object when metrics is undefined', () => {
      expect(MergeRequestStore.buildMetrics(undefined)).toEqual({});
    });

    it('does not format dates when closed_at and merged_at are null', () => {
      const result = MergeRequestStore.buildMetrics({ closed_at: null, merged_at: null });

      expect(result.closedAt).toBeNull();
      expect(result.mergedAt).toBeNull();
    });

    it('formats closedAt when closed_at is provided', () => {
      const result = MergeRequestStore.buildMetrics({
        closed_at: '2020-01-01T00:00:00.000Z',
        merged_at: null,
      });

      expect(result.closedAt).not.toBeNull();
      expect(result.mergedAt).toBeNull();
    });

    it('formats mergedAt when merged_at is provided', () => {
      const result = MergeRequestStore.buildMetrics({
        closed_at: null,
        merged_at: '2020-01-01T00:00:00.000Z',
      });

      expect(result.closedAt).toBeNull();
      expect(result.mergedAt).not.toBeNull();
    });
  });

  describe('setPipelineStatusData', () => {
    it('sets ciStatus field', () => {
      expect(store.ciStatus).toBe('success');

      store.setPipelineStatusData(mockPipelineSubscription);

      expect(store.ciStatus).toBe('running');
    });

    it('sets isPipelineActive field', () => {
      expect(store.isPipelineActive).toBe(false);

      store.setPipelineStatusData(mockPipelineSubscription);

      expect(store.isPipelineActive).toBe(true);
    });

    it('sets isPipelineBlocked field', () => {
      store.onlyAllowMergeIfPipelineSucceeds = true;

      expect(store.isPipelineBlocked).toBe(false);

      store.setPipelineStatusData({ ...mockPipelineSubscription, status: 'MANUAL' });

      expect(store.isPipelineBlocked).toBe(true);
    });

    it('sets isPipelineFailed field', () => {
      expect(store.isPipelineFailed).toBe(false);

      store.setPipelineStatusData({ ...mockPipelineSubscription, status: 'FAILED' });

      expect(store.isPipelineFailed).toBe(true);
    });

    it('sets isPipelinePassing field', () => {
      expect(store.isPipelinePassing).toBe(true);

      store.setPipelineStatusData(mockPipelineSubscription);

      expect(store.isPipelinePassing).toBe(false);
    });

    it('sets isPipelineSkipped field', () => {
      expect(store.isPipelineSkipped).toBe(false);

      store.setPipelineStatusData({ ...mockPipelineSubscription, status: 'SKIPPED' });

      expect(store.isPipelineSkipped).toBe(true);
    });

    it('sets pipelineDetailedStatus field', () => {
      store.setPipelineStatusData(mockPipelineSubscription);

      expect(store.pipelineDetailedStatus).toMatchObject({
        icon: 'status_running',
        id: 'running-1027-1027',
        label: 'running',
        name: 'RUNNING',
        text: 'Running',
        tooltip: 'running',
        details_path: '/root/ci-project/-/pipelines/1027',
      });
    });

    describe('stage updates', () => {
      it('does not modify stages that are not in the subscription data', () => {
        expect(store.pipeline.details.stages[0].status).toMatchObject({
          text: 'failed',
          label: 'failed',
        });

        // current mock data does not contain a stage with ID matching
        // the current store data
        store.setPipelineStatusData(mockPipelineSubscription);

        expect(store.pipeline.details.stages[0].status).toMatchObject({
          text: 'failed',
          label: 'failed',
        });
      });

      it('updates stage status while preserving existing stage properties', () => {
        // update current store pipeline to have IDs that match
        // subscription returned data
        store.pipeline = {
          details: {
            status: {},
            stages: [
              {
                name: 'build',
                id: 1296,
                title: 'build: failed',
                status: {
                  icon: 'status_failed',
                  favicon: 'favicon_status_failed',
                  text: 'failed',
                  label: 'failed',
                  group: 'failed',
                  has_details: true,
                  details_path: '/root/ci-project/-/pipelines/1027#build',
                },
                path: '/root/ci-project/-/pipelines/1027#build',
                dropdown_path: '/root/ci-project/-/pipelines/1027/stage.json?stage=build',
              },
              {
                name: 'test',
                id: 1297,
                title: 'test: pending',
                status: {
                  icon: 'status_pending',
                  favicon: 'favicon_status_pending',
                  text: 'Pending',
                  label: 'pending',
                  group: 'pending',
                  has_details: true,
                  details_path: '/root/ci-project/-/pipelines/1027#test',
                },
                path: '/root/ci-project/-/pipelines/1027#test',
                dropdown_path: '/root/ci-project/-/pipelines/1027/stage.json?stage=test',
              },
            ],
          },
        };

        store.setPipelineStatusData(mockPipelineSubscription);

        const [buildStage, testStage] = store.pipeline.details.stages;

        // status updated from subscription
        expect(buildStage.status.icon).toBe('status_success');
        expect(buildStage.status.text).toBe('Passed');
        expect(buildStage.status.group).toBe('success');
        expect(buildStage.status.details_path).toBe('/root/ci-project/-/pipelines/1027#build');

        // existing properties preserved
        expect(buildStage.name).toBe('build');
        expect(buildStage.dropdown_path).toBe(
          '/root/ci-project/-/pipelines/1027/stage.json?stage=build',
        );
        expect(buildStage.path).toBe('/root/ci-project/-/pipelines/1027#build');
        expect(buildStage.status.has_details).toBe(true);

        // second stage also updated
        expect(testStage.status.icon).toBe('status_running');
        expect(testStage.status.text).toBe('Running');
        expect(testStage.dropdown_path).toBe(
          '/root/ci-project/-/pipelines/1027/stage.json?stage=test',
        );
      });
    });

    describe('when isPostMerge is true', () => {
      it('updates mergePipeline instead of pipeline', () => {
        const originalPipeline = { ...store.pipeline };

        expect(store.mergePipeline).toEqual({});

        store.setPipelineStatusData(mockPipelineSubscription, true);

        expect(store.mergePipeline.details.status.name).toBe('RUNNING');
        expect(store.pipeline).toEqual(originalPipeline);
      });
    });

    it('preserves existing pipeline details properties', () => {
      expect(store.pipeline.details.status.text).toBe('passed');
      expect(store.pipeline.details.artifacts[0]).toEqual({
        job_name: 'generate-artifact',
        job_path: 'bar',
        name: 'generate-artifact',
        path: 'bar',
      });

      store.setPipelineStatusData(mockPipelineSubscription);

      expect(store.pipeline.details.status.text).toBe('Running');
      expect(store.pipeline.details.artifacts[0]).toEqual({
        job_name: 'generate-artifact',
        job_path: 'bar',
        name: 'generate-artifact',
        path: 'bar',
      });
    });
  });
});
