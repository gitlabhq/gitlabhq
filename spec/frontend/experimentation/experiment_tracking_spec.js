import { TRACKING_CONTEXT_SCHEMA } from '~/experimentation/constants';
import ExperimentTracking from '~/experimentation/experiment_tracking';
import { getExperimentData } from '~/experimentation/utils';
import Tracking from '~/tracking';

let experimentTracking;
let label;
let property;

jest.mock('~/tracking');
jest.mock('~/experimentation/utils', () => ({ getExperimentData: jest.fn() }));

const setup = () => {
  experimentTracking = new ExperimentTracking('sidebar_experiment', { label, property });
};

beforeEach(() => {
  document.body.dataset.page = 'issues-page';
});

afterEach(() => {
  label = undefined;
  property = undefined;
});

describe('event', () => {
  beforeEach(() => {
    getExperimentData.mockReturnValue(undefined);
  });

  describe('when experiment data exists for experimentName', () => {
    beforeEach(() => {
      getExperimentData.mockReturnValue('experiment-data');
      setup();
    });

    describe('when providing options', () => {
      label = 'sidebar-drawer';
      property = 'dark-mode';

      it('passes them to the tracking call', () => {
        experimentTracking.event('click_sidebar_close');

        expect(Tracking.event).toHaveBeenCalledTimes(1);
        expect(Tracking.event).toHaveBeenCalledWith('issues-page', 'click_sidebar_close', {
          label: 'sidebar-drawer',
          property: 'dark-mode',
          context: {
            schema: TRACKING_CONTEXT_SCHEMA,
            data: 'experiment-data',
          },
        });
      });
    });

    it('tracks with the correct context', () => {
      experimentTracking.event('click_sidebar_trigger');

      expect(Tracking.event).toHaveBeenCalledTimes(1);
      expect(Tracking.event).toHaveBeenCalledWith('issues-page', 'click_sidebar_trigger', {
        context: {
          schema: TRACKING_CONTEXT_SCHEMA,
          data: 'experiment-data',
        },
      });
    });
  });

  describe('when experiment data does NOT exists for the experimentName', () => {
    beforeEach(() => {
      setup();
    });

    it('does not track', () => {
      experimentTracking.event('click_sidebar_close');

      expect(Tracking.event).not.toHaveBeenCalled();
    });
  });
});
