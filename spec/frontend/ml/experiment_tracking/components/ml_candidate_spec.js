import { GlAlert } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import MlCandidate from '~/ml/experiment_tracking/components/ml_candidate.vue';

describe('MlCandidate', () => {
  let wrapper;

  const createWrapper = () => {
    const candidate = {
      params: [
        { name: 'Algorithm', value: 'Decision Tree' },
        { name: 'MaxDepth', value: '3' },
      ],
      metrics: [
        { name: 'AUC', value: '.55' },
        { name: 'Accuracy', value: '.99' },
      ],
      metadata: [
        { name: 'FileName', value: 'test.py' },
        { name: 'ExecutionTime', value: '.0856' },
      ],
      info: {
        iid: 'candidate_iid',
        artifact_link: 'path_to_artifact',
        experiment_name: 'The Experiment',
        experiment_path: 'path/to/experiment',
        status: 'SUCCESS',
      },
    };

    return mountExtended(MlCandidate, { provide: { candidate } });
  };

  const findAlert = () => wrapper.findComponent(GlAlert);

  it('shows incubation warning', () => {
    wrapper = createWrapper();

    expect(findAlert().exists()).toBe(true);
  });

  it('renders correctly', () => {
    wrapper = createWrapper();

    expect(wrapper.element).toMatchSnapshot();
  });
});
