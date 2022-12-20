import { GlAlert } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import MlExperiment from '~/ml/experiment_tracking/components/ml_experiment.vue';

describe('MlExperiment', () => {
  let wrapper;

  const createWrapper = (candidates = [], metricNames = [], paramNames = []) => {
    return mountExtended(MlExperiment, { provide: { candidates, metricNames, paramNames } });
  };

  const findAlert = () => wrapper.findComponent(GlAlert);

  const findEmptyState = () => wrapper.findByText('This experiment has no logged candidates');

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
          { rmse: 1, l1_ratio: 0.4, details: 'link_to_candidate1', artifact: 'link_to_artifact' },
          { auc: 0.3, l1_ratio: 0.5, details: 'link_to_candidate2' },
        ],
        ['rmse', 'auc', 'mae'],
        ['l1_ratio'],
      );

      expect(wrapper.element).toMatchSnapshot();
    });
  });
});
