import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import MlCandidatesShow from '~/ml/experiment_tracking/routes/candidates/show';
import DeleteButton from '~/ml/experiment_tracking/components/delete_button.vue';
import IncubationAlert from '~/vue_shared/components/incubation/incubation_alert.vue';

describe('MlCandidatesShow', () => {
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
        eid: 'abcdefg',
        path_to_artifact: 'path_to_artifact',
        experiment_name: 'The Experiment',
        experiment_path: 'path/to/experiment',
        status: 'SUCCESS',
        path: 'path_to_candidate',
      },
    };

    wrapper = shallowMountExtended(MlCandidatesShow, { propsData: { candidate } });
  };

  beforeEach(createWrapper);

  const findAlert = () => wrapper.findComponent(IncubationAlert);
  const findDeleteButton = () => wrapper.findComponent(DeleteButton);

  it('shows incubation warning', () => {
    expect(findAlert().exists()).toBe(true);
  });

  it('shows delete button', () => {
    expect(findDeleteButton().exists()).toBe(true);
  });

  it('passes the delete path to delete button', () => {
    expect(findDeleteButton().props('deletePath')).toBe('path_to_candidate');
  });

  it('renders correctly', () => {
    expect(wrapper.element).toMatchSnapshot();
  });
});
