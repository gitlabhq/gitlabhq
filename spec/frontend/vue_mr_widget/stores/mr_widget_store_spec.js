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
      store.setData({ ...mockData });

      expect(store.mergeRequestAddCiConfigPath).toBe('/group2/project2/new/pipeline');
    });

    it('should set humanAccess=Maintainer when user has that role', () => {
      store.setData({ ...mockData });

      expect(store.humanAccess).toBe('Maintainer');
    });

    it('should set pipelinesEmptySvgPath', () => {
      store.setData({ ...mockData });

      expect(store.pipelinesEmptySvgPath).toBe('/path/to/svg');
    });

    it('should set newPipelinePath', () => {
      store.setData({ ...mockData });

      expect(store.newPipelinePath).toBe('/group2/project2/pipelines/new');
    });
  });
});
