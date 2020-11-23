import { convertToCamelCase } from '~/lib/utils/text_utility';
import MergeRequestStore from '~/vue_merge_request_widget/stores/mr_widget_store';
import { stateKey } from '~/vue_merge_request_widget/stores/state_maps';
import mockData from '../mock_data';

describe('MergeRequestStore', () => {
  let store;

  beforeEach(() => {
    store = new MergeRequestStore(mockData);
  });

  describe('setData', () => {
    it('should set isSHAMismatch when the diff SHA changes', () => {
      store.setData({ ...mockData, diff_head_sha: 'a-different-string' });

      expect(store.isSHAMismatch).toBe(true);
    });

    it('should not set isSHAMismatch when other data changes', () => {
      store.setData({ ...mockData, work_in_progress: !mockData.work_in_progress });

      expect(store.isSHAMismatch).toBe(false);
    });

    it('should update cached sha after rebasing', () => {
      store.setData({ ...mockData, diff_head_sha: 'abc123' }, true);

      expect(store.isSHAMismatch).toBe(false);
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

      expect(store.mergeRequestAddCiConfigPath).toBe('/group2/project2/new/pipeline');
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

    it.each(['sast_comparison_path', 'secret_scanning_comparison_path'])(
      'should set %s path',
      property => {
        // Ensure something is set in the mock data
        expect(property in mockData).toBe(true);
        const expectedValue = mockData[property];

        store.setPaths({ ...mockData });

        expect(store[convertToCamelCase(property)]).toBe(expectedValue);
      },
    );
  });
});
