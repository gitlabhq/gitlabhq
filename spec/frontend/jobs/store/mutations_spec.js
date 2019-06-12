import state from '~/jobs/store/state';
import mutations from '~/jobs/store/mutations';
import * as types from '~/jobs/store/mutation_types';

describe('Jobs Store Mutations', () => {
  let stateCopy;

  const html =
    'I, [2018-08-17T22:57:45.707325 #1841]  INFO -- : Writing /builds/ab89e95b0fa0b9272ea0c797b76908f24d36992630e9325273a4ce3.png<br>I';

  beforeEach(() => {
    stateCopy = state();
  });

  describe('SET_JOB_ENDPOINT', () => {
    it('should set jobEndpoint', () => {
      mutations[types.SET_JOB_ENDPOINT](stateCopy, 'job/21312321.json');

      expect(stateCopy.jobEndpoint).toEqual('job/21312321.json');
    });
  });

  describe('HIDE_SIDEBAR', () => {
    it('should set isSidebarOpen to false', () => {
      mutations[types.HIDE_SIDEBAR](stateCopy);

      expect(stateCopy.isSidebarOpen).toEqual(false);
    });
  });

  describe('SHOW_SIDEBAR', () => {
    it('should set isSidebarOpen to true', () => {
      mutations[types.SHOW_SIDEBAR](stateCopy);

      expect(stateCopy.isSidebarOpen).toEqual(true);
    });
  });

  describe('RECEIVE_TRACE_SUCCESS', () => {
    describe('when trace has state', () => {
      it('sets traceState', () => {
        const stateLog =
          'eyJvZmZzZXQiOjczNDQ1MSwibl9vcGVuX3RhZ3MiOjAsImZnX2NvbG9yIjpudWxsLCJiZ19jb2xvciI6bnVsbCwic3R5bGVfbWFzayI6MH0=';
        mutations[types.RECEIVE_TRACE_SUCCESS](stateCopy, {
          state: stateLog,
        });

        expect(stateCopy.traceState).toEqual(stateLog);
      });
    });

    describe('when traceSize is smaller than the total size', () => {
      it('sets isTraceSizeVisible to true', () => {
        mutations[types.RECEIVE_TRACE_SUCCESS](stateCopy, { total: 51184600, size: 1231 });

        expect(stateCopy.isTraceSizeVisible).toEqual(true);
      });
    });

    describe('when traceSize is bigger than the total size', () => {
      it('sets isTraceSizeVisible to false', () => {
        const copy = Object.assign({}, stateCopy, { traceSize: 5118460, size: 2321312 });

        mutations[types.RECEIVE_TRACE_SUCCESS](copy, { total: 511846 });

        expect(copy.isTraceSizeVisible).toEqual(false);
      });
    });

    it('sets trace, trace size and isTraceComplete', () => {
      mutations[types.RECEIVE_TRACE_SUCCESS](stateCopy, {
        append: true,
        html,
        size: 511846,
        complete: true,
      });

      expect(stateCopy.trace).toEqual(html);
      expect(stateCopy.traceSize).toEqual(511846);
      expect(stateCopy.isTraceComplete).toEqual(true);
    });
  });

  describe('STOP_POLLING_TRACE', () => {
    it('sets isTraceComplete to true', () => {
      mutations[types.STOP_POLLING_TRACE](stateCopy);

      expect(stateCopy.isTraceComplete).toEqual(true);
    });
  });

  describe('RECEIVE_TRACE_ERROR', () => {
    it('resets trace state and sets error to true', () => {
      mutations[types.RECEIVE_TRACE_ERROR](stateCopy);

      expect(stateCopy.isTraceComplete).toEqual(true);
    });
  });

  describe('REQUEST_JOB', () => {
    it('sets isLoading to true', () => {
      mutations[types.REQUEST_JOB](stateCopy);

      expect(stateCopy.isLoading).toEqual(true);
    });
  });

  describe('RECEIVE_JOB_SUCCESS', () => {
    it('sets is loading to false', () => {
      mutations[types.RECEIVE_JOB_SUCCESS](stateCopy, { id: 1312321 });

      expect(stateCopy.isLoading).toEqual(false);
    });

    it('sets hasError to false', () => {
      mutations[types.RECEIVE_JOB_SUCCESS](stateCopy, { id: 1312321 });

      expect(stateCopy.hasError).toEqual(false);
    });

    it('sets job data', () => {
      mutations[types.RECEIVE_JOB_SUCCESS](stateCopy, { id: 1312321 });

      expect(stateCopy.job).toEqual({ id: 1312321 });
    });

    it('sets selectedStage when the selectedStage is empty', () => {
      expect(stateCopy.selectedStage).toEqual('');
      mutations[types.RECEIVE_JOB_SUCCESS](stateCopy, { id: 1312321, stage: 'deploy' });

      expect(stateCopy.selectedStage).toEqual('deploy');
    });

    it('does not set selectedStage when the selectedStage is not More', () => {
      stateCopy.selectedStage = 'notify';

      expect(stateCopy.selectedStage).toEqual('notify');
      mutations[types.RECEIVE_JOB_SUCCESS](stateCopy, { id: 1312321, stage: 'deploy' });

      expect(stateCopy.selectedStage).toEqual('notify');
    });
  });

  describe('RECEIVE_JOB_ERROR', () => {
    it('resets job data', () => {
      mutations[types.RECEIVE_JOB_ERROR](stateCopy);

      expect(stateCopy.isLoading).toEqual(false);
      expect(stateCopy.job).toEqual({});
    });
  });

  describe('REQUEST_JOBS_FOR_STAGE', () => {
    it('sets isLoadingJobs to true', () => {
      mutations[types.REQUEST_JOBS_FOR_STAGE](stateCopy, { name: 'deploy' });

      expect(stateCopy.isLoadingJobs).toEqual(true);
    });

    it('sets selectedStage', () => {
      mutations[types.REQUEST_JOBS_FOR_STAGE](stateCopy, { name: 'deploy' });

      expect(stateCopy.selectedStage).toEqual('deploy');
    });
  });

  describe('RECEIVE_JOBS_FOR_STAGE_SUCCESS', () => {
    beforeEach(() => {
      mutations[types.RECEIVE_JOBS_FOR_STAGE_SUCCESS](stateCopy, [{ name: 'karma' }]);
    });

    it('sets isLoadingJobs to false', () => {
      expect(stateCopy.isLoadingJobs).toEqual(false);
    });

    it('sets jobs', () => {
      expect(stateCopy.jobs).toEqual([{ name: 'karma' }]);
    });
  });

  describe('RECEIVE_JOBS_FOR_STAGE_ERROR', () => {
    beforeEach(() => {
      mutations[types.RECEIVE_JOBS_FOR_STAGE_ERROR](stateCopy);
    });

    it('sets isLoadingJobs to false', () => {
      expect(stateCopy.isLoadingJobs).toEqual(false);
    });

    it('resets jobs', () => {
      expect(stateCopy.jobs).toEqual([]);
    });
  });
});
