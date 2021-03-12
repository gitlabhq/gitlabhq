import { shallowMount } from '@vue/test-utils';
import LearnGitlabA from '~/pages/projects/learn_gitlab/components/learn_gitlab_a.vue';
import { testActions } from './mock_data';

describe('Learn GitLab Design A', () => {
  let wrapper;

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const createWrapper = () => {
    wrapper = shallowMount(LearnGitlabA, { propsData: { actions: testActions } });
  };

  it('should render the loading state', () => {
    createWrapper();

    expect(wrapper.element).toMatchSnapshot();
  });
});
