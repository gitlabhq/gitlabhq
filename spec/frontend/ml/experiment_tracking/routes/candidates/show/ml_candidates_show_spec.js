import { shallowMount } from '@vue/test-utils';
import MlCandidatesShow from '~/ml/experiment_tracking/routes/candidates/show';
import DeleteButton from '~/ml/experiment_tracking/components/delete_button.vue';
import CandidateDetail from '~/ml/model_registry/components/candidate_detail.vue';
import ModelExperimentsHeader from '~/ml/experiment_tracking/components/model_experiments_header.vue';
import { newCandidate } from 'jest/ml/model_registry/mock_data';

describe('MlCandidatesShow', () => {
  let wrapper;
  const CANDIDATE = newCandidate();

  const createWrapper = () => {
    wrapper = shallowMount(MlCandidatesShow, {
      propsData: { candidate: CANDIDATE },
    });
  };

  const findDeleteButton = () => wrapper.findComponent(DeleteButton);
  const findHeader = () => wrapper.findComponent(ModelExperimentsHeader);
  const findCandidateDetail = () => wrapper.findComponent(CandidateDetail);

  beforeEach(() => createWrapper());

  it('shows delete button', () => {
    expect(findDeleteButton().exists()).toBe(true);
  });

  it('passes the delete path to delete button', () => {
    expect(findDeleteButton().props('deletePath')).toBe('path_to_candidate');
  });

  it('passes the right title', () => {
    expect(findHeader().props('pageTitle')).toBe('Model candidate details');
  });

  it('creates the candidate detail section', () => {
    expect(findCandidateDetail().props('candidate')).toBe(CANDIDATE);
  });
});
