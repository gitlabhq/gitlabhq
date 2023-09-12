import * as getters from '~/ci/job_details/store/getters';
import state from '~/ci/job_details/store/state';

describe('Job Store Getters', () => {
  let localState;

  beforeEach(() => {
    localState = state();
  });

  describe('headerTime', () => {
    describe('when the job has started key', () => {
      it('returns started_at value', () => {
        const started = '2018-08-31T16:20:49.023Z';
        const startedAt = '2018-08-31T16:20:49.023Z';
        localState.job.started_at = startedAt;
        localState.job.started = started;

        expect(getters.headerTime(localState)).toEqual(startedAt);
      });
    });

    describe('when the job does not have started key', () => {
      it('returns created_at value', () => {
        const created = '2018-08-31T16:20:49.023Z';
        localState.job.created_at = created;

        expect(getters.headerTime(localState)).toEqual(created);
      });
    });
  });

  describe('shouldRenderCalloutMessage', () => {
    describe('with status and callout message', () => {
      it('returns true', () => {
        localState.job.callout_message = 'Callout message';
        localState.job.status = { icon: 'passed' };

        expect(getters.shouldRenderCalloutMessage(localState)).toEqual(true);
      });
    });

    describe('without status & with callout message', () => {
      it('returns false', () => {
        localState.job.callout_message = 'Callout message';

        expect(getters.shouldRenderCalloutMessage(localState)).toEqual(false);
      });
    });

    describe('with status & without callout message', () => {
      it('returns false', () => {
        localState.job.status = { icon: 'passed' };

        expect(getters.shouldRenderCalloutMessage(localState)).toEqual(false);
      });
    });
  });

  describe('shouldRenderTriggeredLabel', () => {
    describe('when started equals null', () => {
      it('returns false', () => {
        localState.job.started_at = null;

        expect(getters.shouldRenderTriggeredLabel(localState)).toEqual(false);
      });
    });

    describe('when started equals string', () => {
      it('returns true', () => {
        localState.job.started_at = '2018-08-31T16:20:49.023Z';

        expect(getters.shouldRenderTriggeredLabel(localState)).toEqual(true);
      });
    });
  });

  describe('hasEnvironment', () => {
    describe('without `deployment_status`', () => {
      it('returns false', () => {
        expect(getters.hasEnvironment(localState)).toEqual(false);
      });
    });

    describe('with an empty object for `deployment_status`', () => {
      it('returns false', () => {
        localState.job.deployment_status = {};

        expect(getters.hasEnvironment(localState)).toEqual(false);
      });
    });

    describe('when `deployment_status` is defined and not empty', () => {
      it('returns true', () => {
        localState.job.deployment_status = {
          status: 'creating',
          environment: {
            last_deployment: {},
          },
        };

        expect(getters.hasEnvironment(localState)).toEqual(true);
      });
    });
  });

  describe('hasJobLog', () => {
    describe('when has_trace is true', () => {
      it('returns true', () => {
        localState.job.has_trace = true;
        localState.job.status = {};

        expect(getters.hasJobLog(localState)).toEqual(true);
      });
    });

    describe('when job is running', () => {
      it('returns true', () => {
        localState.job.has_trace = false;
        localState.job.status = { group: 'running' };

        expect(getters.hasJobLog(localState)).toEqual(true);
      });
    });

    describe('when has_trace is false and job is not running', () => {
      it('returns false', () => {
        localState.job.has_trace = false;
        localState.job.status = { group: 'pending' };

        expect(getters.hasJobLog(localState)).toEqual(false);
      });
    });
  });

  describe('emptyStateIllustration', () => {
    describe('with defined illustration', () => {
      it('returns the state illustration object', () => {
        localState.job.status = {
          illustration: {
            path: 'foo',
          },
        };

        expect(getters.emptyStateIllustration(localState)).toEqual({ path: 'foo' });
      });
    });

    describe('when illustration is not defined', () => {
      it('returns an empty object', () => {
        expect(getters.emptyStateIllustration(localState)).toEqual({});
      });
    });
  });

  describe('shouldRenderSharedRunnerLimitWarning', () => {
    describe('without runners information', () => {
      it('returns false', () => {
        expect(getters.shouldRenderSharedRunnerLimitWarning(localState)).toEqual(false);
      });
    });

    describe('with runners information', () => {
      describe('when used quota is less than limit', () => {
        it('returns false', () => {
          localState.job.runners = {
            quota: {
              used: 33,
              limit: 2000,
            },
            available: true,
            online: true,
          };

          expect(getters.shouldRenderSharedRunnerLimitWarning(localState)).toEqual(false);
        });
      });

      describe('when used quota is equal to limit', () => {
        it('returns true', () => {
          localState.job.runners = {
            quota: {
              used: 2000,
              limit: 2000,
            },
            available: true,
            online: true,
          };

          expect(getters.shouldRenderSharedRunnerLimitWarning(localState)).toEqual(true);
        });
      });

      describe('when used quota is bigger than limit', () => {
        it('returns true', () => {
          localState.job.runners = {
            quota: {
              used: 2002,
              limit: 2000,
            },
            available: true,
            online: true,
          };

          expect(getters.shouldRenderSharedRunnerLimitWarning(localState)).toEqual(true);
        });
      });
    });
  });

  describe('hasOfflineRunnersForProject', () => {
    describe('with available and offline runners', () => {
      it('returns true', () => {
        localState.job.runners = {
          available: true,
          online: false,
        };

        expect(getters.hasOfflineRunnersForProject(localState)).toEqual(true);
      });
    });

    describe('with non available runners', () => {
      it('returns false', () => {
        localState.job.runners = {
          available: false,
          online: false,
        };

        expect(getters.hasOfflineRunnersForProject(localState)).toEqual(false);
      });
    });

    describe('with online runners', () => {
      it('returns false', () => {
        localState.job.runners = {
          available: false,
          online: true,
        };

        expect(getters.hasOfflineRunnersForProject(localState)).toEqual(false);
      });
    });
  });
});
