import { GlAlert } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import ShowExperiment from '~/ml/experiment_tracking/components/experiment.vue';

describe('ShowExperiment', () => {
  let wrapper;

  const createWrapper = (candidates = [], metricNames = [], paramNames = []) => {
    return mountExtended(ShowExperiment, { provide: { candidates, metricNames, paramNames } });
  };

  const findAlert = () => wrapper.findComponent(GlAlert);

  const findEmptyState = () => wrapper.findByText('This Experiment has no logged Candidates');

  it('shows incubation warning', () => {
    wrapper = createWrapper();

    expect(findAlert().exists()).toBe(true);
  });

  describe('no candidates', () => {
    it('shows empty state', () => {
      wrapper = createWrapper();

      expect(findEmptyState().exists()).toBe(true);
    });
  });

  describe('with candidates', () => {
    it('renders correctly', () => {
      wrapper = createWrapper(
        [
          { rmse: 1, l1_ratio: 0.4 },
          { auc: 0.3, l1_ratio: 0.5 },
        ],
        ['rmse', 'auc', 'mae'],
        ['l1_ratio'],
      );

      expect(wrapper.element).toMatchSnapshot();
    });
  });
});
