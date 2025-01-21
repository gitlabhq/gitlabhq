import { shallowMount } from '@vue/test-utils';
import MlCandidatesShow from '~/ml/experiment_tracking/routes/candidates/show';
import CandidateHeader from '~/ml/experiment_tracking/routes/candidates/show/candidate_header.vue';
import CandidateDetail from '~/ml/experiment_tracking/routes/candidates/show/candidate_detail.vue';
import { newCandidate } from 'jest/ml/model_registry/mock_data';

describe('MlCandidatesShow', () => {
  let wrapper;
  const candidate = newCandidate();

  const createWrapper = () => {
    wrapper = shallowMount(MlCandidatesShow, {
      propsData: { candidate },
    });
  };

  const findCandidateHeader = () => wrapper.findComponent(CandidateHeader);
  const findCandidateDetail = () => wrapper.findComponent(CandidateDetail);

  beforeEach(() => createWrapper());

  it('creates the candidate header section', () => {
    expect(findCandidateHeader().props('candidate')).toBe(candidate);
  });

  it('creates the candidate detail section', () => {
    expect(findCandidateDetail().props('candidate')).toBe(candidate);
  });
});
