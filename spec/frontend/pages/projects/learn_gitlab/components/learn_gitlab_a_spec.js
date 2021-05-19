import { GlProgressBar } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import LearnGitlabA from '~/pages/projects/learn_gitlab/components/learn_gitlab_a.vue';
import { testActions, testSections } from './mock_data';

describe('Learn GitLab Design A', () => {
  let wrapper;

  const createWrapper = () => {
    wrapper = mount(LearnGitlabA, { propsData: { actions: testActions, sections: testSections } });
  };

  beforeEach(() => {
    createWrapper();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('renders correctly', () => {
    expect(wrapper.element).toMatchSnapshot();
  });

  it('renders the progress percentage', () => {
    const text = wrapper.find('[data-testid="completion-percentage"]').text();

    expect(text).toBe('22% completed');
  });

  it('renders the progress bar with correct values', () => {
    const progressBar = wrapper.findComponent(GlProgressBar);

    expect(progressBar.attributes('value')).toBe('2');
    expect(progressBar.attributes('max')).toBe('9');
  });
});
