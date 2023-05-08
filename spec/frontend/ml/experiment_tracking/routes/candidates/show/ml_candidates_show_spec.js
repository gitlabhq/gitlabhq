import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import MlCandidatesShow from '~/ml/experiment_tracking/routes/candidates/show';
import { TITLE_LABEL } from '~/ml/experiment_tracking/routes/candidates/show/translations';
import DeleteButton from '~/ml/experiment_tracking/components/delete_button.vue';
import ModelExperimentsHeader from '~/ml/experiment_tracking/components/model_experiments_header.vue';

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

  const findDeleteButton = () => wrapper.findComponent(DeleteButton);
  const findHeader = () => wrapper.findComponent(ModelExperimentsHeader);

  it('shows delete button', () => {
    expect(findDeleteButton().exists()).toBe(true);
  });

  it('passes the delete path to delete button', () => {
    expect(findDeleteButton().props('deletePath')).toBe('path_to_candidate');
  });

  it('passes the right title', () => {
    expect(findHeader().props('pageTitle')).toBe(TITLE_LABEL);
  });

  it('renders correctly', () => {
    expect(wrapper.element).toMatchSnapshot();
  });
});
