import * as types from '~/ide/stores/modules/pipelines/mutation_types';
import mutations from '~/ide/stores/modules/pipelines/mutations';
import state from '~/ide/stores/modules/pipelines/state';
import { fullPipelinesResponse, stages, jobs } from '../../../mock_data';

describe('IDE pipelines mutations', () => {
  let mockedState;

  beforeEach(() => {
    mockedState = state();
  });

  describe('REQUEST_LATEST_PIPELINE', () => {
    it('sets loading to true', () => {
      mutations[types.REQUEST_LATEST_PIPELINE](mockedState);

      expect(mockedState.isLoadingPipeline).toBe(true);
    });
  });

  describe('RECEIVE_LASTEST_PIPELINE_ERROR', () => {
    it('sets loading to false', () => {
      mutations[types.RECEIVE_LASTEST_PIPELINE_ERROR](mockedState);

      expect(mockedState.isLoadingPipeline).toBe(false);
    });
  });

  describe('RECEIVE_LASTEST_PIPELINE_SUCCESS', () => {
    const itSetsPipelineLoadingStates = () => {
      it('sets has loaded to true', () => {
        expect(mockedState.hasLoadedPipeline).toBe(true);
      });

      it('sets loading to false on success', () => {
        expect(mockedState.isLoadingPipeline).toBe(false);
      });
    };

    describe('with pipeline', () => {
      beforeEach(() => {
        mutations[types.RECEIVE_LASTEST_PIPELINE_SUCCESS](
          mockedState,
          fullPipelinesResponse.data.pipelines[0],
        );
      });

      itSetsPipelineLoadingStates();

      it('sets latestPipeline', () => {
        expect(mockedState.latestPipeline).toEqual({
          id: '51',
          path: 'test',
          commit: { id: '123' },
          details: { status: expect.any(Object) },
          yamlError: undefined,
        });
      });

      it('sets stages', () => {
        expect(mockedState.stages.length).toBe(2);
        expect(mockedState.stages).toEqual([
          {
            id: 0,
            dropdownPath: stages[0].dropdown_path,
            name: stages[0].name,
            status: stages[0].status,
            isCollapsed: false,
            isLoading: false,
            jobs: [],
          },
          {
            id: 1,
            dropdownPath: stages[1].dropdown_path,
            name: stages[1].name,
            status: stages[1].status,
            isCollapsed: false,
            isLoading: false,
            jobs: [],
          },
        ]);
      });
    });

    describe('with null', () => {
      beforeEach(() => {
        mutations[types.RECEIVE_LASTEST_PIPELINE_SUCCESS](mockedState, null);
      });

      itSetsPipelineLoadingStates();

      it('does not set latest pipeline if pipeline is null', () => {
        expect(mockedState.latestPipeline).toEqual(null);
      });
    });
  });

  describe('REQUEST_JOBS', () => {
    beforeEach(() => {
      mockedState.stages = stages.map((stage, i) => ({ ...stage, id: i }));
    });

    it('sets isLoading on stage', () => {
      mutations[types.REQUEST_JOBS](mockedState, mockedState.stages[0].id);

      expect(mockedState.stages[0].isLoading).toBe(true);
    });
  });

  describe('RECEIVE_JOBS_ERROR', () => {
    beforeEach(() => {
      mockedState.stages = stages.map((stage, i) => ({ ...stage, id: i }));
    });

    it('sets isLoading on stage after error', () => {
      mutations[types.RECEIVE_JOBS_ERROR](mockedState, mockedState.stages[0].id);

      expect(mockedState.stages[0].isLoading).toBe(false);
    });
  });

  describe('RECEIVE_JOBS_SUCCESS', () => {
    let data;

    beforeEach(() => {
      mockedState.stages = stages.map((stage, i) => ({ ...stage, id: i }));

      data = { latest_statuses: [...jobs] };
    });

    it('updates loading', () => {
      mutations[types.RECEIVE_JOBS_SUCCESS](mockedState, { id: mockedState.stages[0].id, data });
      expect(mockedState.stages[0].isLoading).toBe(false);
    });

    it('sets jobs on stage', () => {
      mutations[types.RECEIVE_JOBS_SUCCESS](mockedState, { id: mockedState.stages[0].id, data });
      expect(mockedState.stages[0].jobs.length).toBe(jobs.length);
      expect(mockedState.stages[0].jobs).toEqual(
        jobs.map((job) => ({
          id: job.id,
          name: job.name,
          status: job.status,
          path: job.build_path,
          rawPath: `${job.build_path}/raw`,
          started: job.started,
          isLoading: false,
          output: '',
        })),
      );
    });
  });

  describe('TOGGLE_STAGE_COLLAPSE', () => {
    beforeEach(() => {
      mockedState.stages = stages.map((stage, i) => ({ ...stage, id: i, isCollapsed: false }));
    });

    it('toggles collapsed state', () => {
      mutations[types.TOGGLE_STAGE_COLLAPSE](mockedState, mockedState.stages[0].id);

      expect(mockedState.stages[0].isCollapsed).toBe(true);

      mutations[types.TOGGLE_STAGE_COLLAPSE](mockedState, mockedState.stages[0].id);

      expect(mockedState.stages[0].isCollapsed).toBe(false);
    });
  });

  describe('SET_DETAIL_JOB', () => {
    it('sets detail job', () => {
      mutations[types.SET_DETAIL_JOB](mockedState, jobs[0]);

      expect(mockedState.detailJob).toEqual(jobs[0]);
    });
  });

  describe('REQUEST_JOB_LOGS', () => {
    beforeEach(() => {
      mockedState.detailJob = { ...jobs[0] };
    });

    it('sets loading on detail job', () => {
      mutations[types.REQUEST_JOB_LOGS](mockedState);

      expect(mockedState.detailJob.isLoading).toBe(true);
    });
  });

  describe('RECEIVE_JOB_LOGS_ERROR', () => {
    beforeEach(() => {
      mockedState.detailJob = { ...jobs[0], isLoading: true };
    });

    it('sets loading to false on detail job', () => {
      mutations[types.RECEIVE_JOB_LOGS_ERROR](mockedState);

      expect(mockedState.detailJob.isLoading).toBe(false);
    });
  });

  describe('RECEIVE_JOB_LOGS_SUCCESS', () => {
    beforeEach(() => {
      mockedState.detailJob = { ...jobs[0], isLoading: true };
    });

    it('sets output on detail job', () => {
      mutations[types.RECEIVE_JOB_LOGS_SUCCESS](mockedState, { html: 'html' });
      expect(mockedState.detailJob.output).toBe('html');
      expect(mockedState.detailJob.isLoading).toBe(false);
    });
  });
});
