import PipelineStore from '~/ci/pipeline_details/stores/pipelines_store';

describe('Pipelines Store', () => {
  let store;

  beforeEach(() => {
    store = new PipelineStore();
  });

  it('should be initialized with an empty state', () => {
    expect(store.state.pipelines).toEqual([]);
    expect(store.state.count).toEqual({});
    expect(store.state.pageInfo).toEqual({});
  });

  describe('storePipelines', () => {
    it('should use the default parameter if none is provided', () => {
      store.storePipelines();

      expect(store.state.pipelines).toEqual([]);
    });

    it('should store the provided array', () => {
      const array = [
        { id: 1, status: 'running' },
        { id: 2, status: 'success' },
      ];
      store.storePipelines(array);

      expect(store.state.pipelines).toEqual(array);
    });

    describe('when pipeline creation is async', () => {
      describe('when a new pipeline is added to the store', () => {
        it('sets the value of `isRunningMergeRequestPipeline` to false', () => {
          const existingPipelines = [{ created_at: '2023' }];
          store.storePipelines(existingPipelines, true);
          store.state.isRunningMergeRequestPipeline = true;

          const updatedPipelines = [{ created_at: '2024' }, { created_at: '2023' }];
          store.storePipelines(updatedPipelines, true);

          expect(store.state.isRunningMergeRequestPipeline).toBe(false);
        });
      });

      describe('when no new pipelines are added to the store', () => {
        it('does not change the value of `isRunningMergeRequestPipeline`', () => {
          const existingPipelines = [{ created_at: '2023' }];
          store.storePipelines(existingPipelines, true);
          store.state.isRunningMergeRequestPipeline = true;

          const updatedPipelines = [{ created_at: '2023' }];
          store.storePipelines(updatedPipelines, true);

          expect(store.state.isRunningMergeRequestPipeline).toBe(true);
        });
      });
    });
  });

  describe('storeCount', () => {
    it('should use the default parameter if none is provided', () => {
      store.storeCount();

      expect(store.state.count).toEqual({});
    });

    it('should store the provided count', () => {
      const count = { all: 20, finished: 10 };
      store.storeCount(count);

      expect(store.state.count).toEqual(count);
    });
  });

  describe('storePagination', () => {
    it('should use the default parameter if none is provided', () => {
      store.storePagination();

      expect(store.state.pageInfo).toEqual({});
    });

    it('should store pagination information normalized and parsed', () => {
      const pagination = {
        'X-nExt-pAge': '2',
        'X-page': '1',
        'X-Per-Page': '1',
        'X-Prev-Page': '2',
        'X-TOTAL': '37',
        'X-Total-Pages': '2',
      };

      const expectedResult = {
        perPage: 1,
        page: 1,
        total: 37,
        totalPages: 2,
        nextPage: 2,
        previousPage: 2,
      };

      store.storePagination(pagination);

      expect(store.state.pageInfo).toEqual(expectedResult);
    });
  });
});
