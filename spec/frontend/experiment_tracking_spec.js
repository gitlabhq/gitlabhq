import ExperimentTracking from '~/experiment_tracking';
import Tracking from '~/tracking';

jest.mock('~/tracking');

const oldGon = window.gon;

let newGon = {};
let experimentTracking;
let label;
let property;

const setup = () => {
  window.gon = newGon;
  experimentTracking = new ExperimentTracking('sidebar_experiment', { label, property });
};

beforeEach(() => {
  document.body.dataset.page = 'issues-page';
});

afterEach(() => {
  window.gon = oldGon;
  Tracking.mockClear();
  label = undefined;
  property = undefined;
});

describe('event', () => {
  describe('when experiment data exists for experimentName', () => {
    beforeEach(() => {
      newGon = { global: { experiment: { sidebar_experiment: 'experiment-data' } } };
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
            schema: 'iglu:com.gitlab/gitlab_experiment/jsonschema/1-0-0',
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
          schema: 'iglu:com.gitlab/gitlab_experiment/jsonschema/1-0-0',
          data: 'experiment-data',
        },
      });
    });
  });

  describe('when experiment data does NOT exists for the experimentName', () => {
    beforeEach(() => {
      newGon = { global: { experiment: { unrelated_experiment: 'not happening' } } };
      setup();
    });

    it('does not track', () => {
      experimentTracking.event('click_sidebar_close');

      expect(Tracking.event).not.toHaveBeenCalled();
    });
  });
});
