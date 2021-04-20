import { shallowMount } from '@vue/test-utils';
import LearnGitlabSectionLink from '~/pages/projects/learn_gitlab/components/learn_gitlab_section_link.vue';

const defaultAction = 'gitWrite';
const defaultProps = {
  title: 'Create Repository',
  description: 'Some description',
  url: 'https://example.com',
  completed: false,
};

describe('Learn GitLab Section Link', () => {
  let wrapper;

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const createWrapper = (action = defaultAction, props = {}) => {
    wrapper = shallowMount(LearnGitlabSectionLink, {
      propsData: { action, value: { ...defaultProps, ...props } },
    });
  };

  it('renders no icon when not completed', () => {
    createWrapper(undefined, { completed: false });

    expect(wrapper.find('[data-testid="completed-icon"]').exists()).toBe(false);
  });

  it('renders the completion icon when completed', () => {
    createWrapper(undefined, { completed: true });

    expect(wrapper.find('[data-testid="completed-icon"]').exists()).toBe(true);
  });

  it('renders no trial only when it is not required', () => {
    createWrapper();

    expect(wrapper.find('[data-testid="trial-only"]').exists()).toBe(false);
  });

  it('renders trial only when trial is required', () => {
    createWrapper('codeOwnersEnabled');

    expect(wrapper.find('[data-testid="trial-only"]').exists()).toBe(true);
  });
});
