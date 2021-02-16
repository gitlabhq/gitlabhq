import { shallowMount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import LearnGitlabA from '~/pages/projects/learn_gitlab/components/learn_gitlab_a.vue';

const TEST_ACTIONS = {
  gitWrite: {
    url: 'http://example.com/',
    completed: true,
  },
  userAdded: {
    url: 'http://example.com/',
    completed: true,
  },
  pipelineCreated: {
    url: 'http://example.com/',
    completed: true,
  },
  trialStarted: {
    url: 'http://example.com/',
    completed: false,
  },
  codeOwnersEnabled: {
    url: 'http://example.com/',
    completed: false,
  },
  requiredMrApprovalsEnabled: {
    url: 'http://example.com/',
    completed: false,
  },
  mergeRequestCreated: {
    url: 'http://example.com/',
    completed: false,
  },
  securityScanEnabled: {
    url: 'http://example.com/',
    completed: false,
  },
};

describe('Learn GitLab Design B', () => {
  let wrapper;

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const createWrapper = () => {
    wrapper = extendedWrapper(
      shallowMount(LearnGitlabA, {
        propsData: {
          actions: TEST_ACTIONS,
        },
      }),
    );
  };

  it('should render the loading state', () => {
    createWrapper();

    expect(wrapper.element).toMatchSnapshot();
  });
});
