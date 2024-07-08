import * as types from '~/ci/job_details/store/mutation_types';
import mutations from '~/ci/job_details/store/mutations';
import state from '~/ci/job_details/store/state';
import * as utils from '~/ci/job_details/store/utils';

describe('Jobs Store Mutations', () => {
  let stateCopy;

  const html =
    'I, [2018-08-17T22:57:45.707325 #1841]  INFO -- : Writing /builds/ab89e95b0fa0b9272ea0c797b76908f24d36992630e9325273a4ce3.png<br>I';

  beforeEach(() => {
    stateCopy = state();
  });

  describe('SET_JOB_LOG_OPTIONS', () => {
    it('should set jobEndpoint', () => {
      mutations[types.SET_JOB_LOG_OPTIONS](stateCopy, {
        jobEndpoint: '/group1/project1/-/jobs/99.json',
        logEndpoint: '/group1/project1/-/jobs/99/trace',
        testReportSummaryUrl: '/group1/project1/-/jobs/99/test_report_summary.json',
      });

      expect(stateCopy).toMatchObject({
        jobEndpoint: '/group1/project1/-/jobs/99.json',
        logEndpoint: '/group1/project1/-/jobs/99/trace',
        testReportSummaryUrl: '/group1/project1/-/jobs/99/test_report_summary.json',
      });
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

  describe('RECEIVE_JOB_LOG_SUCCESS', () => {
    describe('when job log has state', () => {
      it('sets jobLogState', () => {
        const logState =
          'eyJvZmZzZXQiOjczNDQ1MSwibl9vcGVuX3RhZ3MiOjAsImZnX2NvbG9yIjpudWxsLCJiZ19jb2xvciI6bnVsbCwic3R5bGVfbWFzayI6MH0=';
        mutations[types.RECEIVE_JOB_LOG_SUCCESS](stateCopy, {
          state: logState,
        });

        expect(stateCopy.jobLogState).toEqual(logState);
      });
    });

    describe('when jobLogSize is smaller than the total size', () => {
      it('sets isJobLogSizeVisible to true', () => {
        mutations[types.RECEIVE_JOB_LOG_SUCCESS](stateCopy, { total: 51184600, size: 1231 });

        expect(stateCopy.isJobLogSizeVisible).toEqual(true);
      });
    });

    describe('when jobLogSize is bigger than the total size', () => {
      it('sets isJobLogSizeVisible to false', () => {
        const copy = { ...stateCopy, jobLogSize: 5118460, size: 2321312 };

        mutations[types.RECEIVE_JOB_LOG_SUCCESS](copy, { total: 511846 });

        expect(copy.isJobLogSizeVisible).toEqual(false);
      });
    });

    it('sets job log size and isJobLogComplete', () => {
      mutations[types.RECEIVE_JOB_LOG_SUCCESS](stateCopy, {
        append: true,
        html,
        size: 511846,
        complete: true,
        lines: [],
      });

      expect(stateCopy.jobLogSize).toEqual(511846);
      expect(stateCopy.isJobLogComplete).toEqual(true);
    });

    describe('with new job log', () => {
      const mockLog = {
        append: false,
        size: 511846,
        complete: true,
        lines: [
          {
            offset: 1,
            content: [{ text: 'Line content' }],
          },
        ],
      };

      beforeEach(() => {
        jest.spyOn(utils, 'logLinesParser');
      });

      afterEach(() => {
        utils.logLinesParser.mockRestore();
      });

      describe('log.lines', () => {
        describe('when it is defined', () => {
          it('sets the parsed log', () => {
            mutations[types.RECEIVE_JOB_LOG_SUCCESS](stateCopy, mockLog);

            expect(utils.logLinesParser).toHaveBeenCalledWith(mockLog.lines, {}, '');

            expect(stateCopy.jobLog).toEqual([
              {
                offset: 1,
                content: [{ text: 'Line content' }],
                lineNumber: 1,
              },
            ]);
          });
        });

        describe('when it is defined and location.hash is set', () => {
          beforeEach(() => {
            window.location.hash = '#L1';
          });

          it('sets the parsed log', () => {
            mutations[types.RECEIVE_JOB_LOG_SUCCESS](stateCopy, mockLog);

            expect(utils.logLinesParser).toHaveBeenCalledWith(mockLog.lines, {}, '#L1');

            expect(stateCopy.jobLog).toEqual([
              {
                offset: 1,
                content: [{ text: 'Line content' }],
                lineNumber: 1,
              },
            ]);
          });

          describe('when append is true', () => {
            it('sets the parsed log', () => {
              stateCopy.jobLog = [
                {
                  offset: 0,
                  content: [{ text: 'Previous line content' }],
                  lineNumber: 1,
                },
              ];

              mutations[types.RECEIVE_JOB_LOG_SUCCESS](stateCopy, {
                ...mockLog,
                append: true,
              });

              expect(stateCopy.jobLog).toEqual([
                {
                  offset: 0,
                  content: [{ text: 'Previous line content' }],
                  lineNumber: 1,
                },
                {
                  offset: 1,
                  content: [{ text: 'Line content' }],
                  lineNumber: 2,
                },
              ]);
            });
          });
        });

        describe('when it is null', () => {
          it('sets the default value', () => {
            mutations[types.RECEIVE_JOB_LOG_SUCCESS](stateCopy, {
              append: true,
              html,
              size: 511846,
              complete: false,
              lines: null,
            });

            expect(stateCopy.jobLog).toEqual([]);
          });
        });
      });
    });
  });

  describe('SET_JOB_LOG_TIMEOUT', () => {
    it('sets the jobLogTimeout id', () => {
      const id = 7;

      expect(stateCopy.jobLogTimeout).not.toEqual(id);

      mutations[types.SET_JOB_LOG_TIMEOUT](stateCopy, id);

      expect(stateCopy.jobLogTimeout).toEqual(id);
    });
  });

  describe('STOP_POLLING_JOB_LOG', () => {
    it('sets isJobLogComplete to true', () => {
      mutations[types.STOP_POLLING_JOB_LOG](stateCopy);

      expect(stateCopy.isJobLogComplete).toEqual(true);
    });
  });

  describe('TOGGLE_COLLAPSIBLE_LINE', () => {
    it('toggles the `isClosed` property of the provided object', () => {
      stateCopy.jobLogSections = {
        'step-script': { isClosed: true },
      };

      mutations[types.TOGGLE_COLLAPSIBLE_LINE](stateCopy, 'step-script');

      expect(stateCopy.jobLogSections['step-script'].isClosed).toEqual(false);

      mutations[types.TOGGLE_COLLAPSIBLE_LINE](stateCopy, 'step-script');

      expect(stateCopy.jobLogSections['step-script'].isClosed).toEqual(true);
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
    it("resets job data when the job doesn't have a log", () => {
      stateCopy = {
        isLoading: true,
        hasError: false,
        job: {},
      };

      mutations[types.RECEIVE_JOB_ERROR](stateCopy);

      expect(stateCopy.hasError).toEqual(true);
      expect(stateCopy.isLoading).toEqual(false);
      expect(stateCopy.job).toEqual({});
    });

    it("doesn't reset job data when the job has a log", () => {
      stateCopy = {
        isLoading: true,
        hasError: false,
        job: {
          has_trace: true,
          status: {
            group: 'running',
          },
        },
      };

      mutations[types.RECEIVE_JOB_ERROR](stateCopy);

      expect(stateCopy.hasError).toEqual(true);
      expect(stateCopy.isLoading).toEqual(false);
      expect(stateCopy.job).toMatchObject(stateCopy.job);
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

  describe('ENTER_FULLSCREEN_SUCCESS', () => {
    beforeEach(() => {
      mutations[types.ENTER_FULLSCREEN_SUCCESS](stateCopy);
    });

    it('sets fullScreenEnabled to true', () => {
      expect(stateCopy.fullScreenEnabled).toEqual(true);
    });
  });

  describe('EXIT_FULLSCREEN_SUCCESS', () => {
    beforeEach(() => {
      mutations[types.EXIT_FULLSCREEN_SUCCESS](stateCopy);
    });

    it('sets fullScreenEnabled to false', () => {
      expect(stateCopy.fullScreenEnabled).toEqual(false);
    });
  });

  describe('FULL_SCREEN_CONTAINER_SET_UP', () => {
    beforeEach(() => {
      mutations[types.FULL_SCREEN_CONTAINER_SET_UP](stateCopy, true);
    });

    it('sets fullScreenEnabled to true', () => {
      expect(stateCopy.fullScreenContainerSetUp).toEqual(true);
    });
  });
});
