import { shallowMount } from '@vue/test-utils';
import LearnGitlabInfoCard from '~/pages/projects/learn_gitlab/components/learn_gitlab_info_card.vue';

const defaultProps = {
  title: 'Create Repository',
  description: 'Some description',
  actionLabel: 'Create Repository now',
  url: 'https://example.com',
  completed: false,
  svg: 'https://example.com/illustration.svg',
};

describe('Learn GitLab Info Card', () => {
  let wrapper;

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const createWrapper = (props = {}) => {
    wrapper = shallowMount(LearnGitlabInfoCard, {
      propsData: { ...defaultProps, ...props },
    });
  };

  it('renders no icon when not completed', () => {
    createWrapper({ completed: false });

    expect(wrapper.find('[data-testid="completed-icon"]').exists()).toBe(false);
  });

  it('renders the completion icon when completed', () => {
    createWrapper({ completed: true });

    expect(wrapper.find('[data-testid="completed-icon"]').exists()).toBe(true);
  });

  it('renders no trial only when it is not required', () => {
    createWrapper();

    expect(wrapper.find('[data-testid="trial-only"]').exists()).toBe(false);
  });

  it('renders trial only when trial is required', () => {
    createWrapper({ trialRequired: true });

    expect(wrapper.find('[data-testid="trial-only"]').exists()).toBe(true);
  });

  it('renders completion icon when completed a trial-only feature', () => {
    createWrapper({ trialRequired: true, completed: true });

    expect(wrapper.find('[data-testid="trial-only"]').exists()).toBe(false);
    expect(wrapper.find('[data-testid="completed-icon"]').exists()).toBe(true);
  });
});
