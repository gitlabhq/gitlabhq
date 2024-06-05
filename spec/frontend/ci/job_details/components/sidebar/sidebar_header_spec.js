import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import SidebarHeader from '~/ci/job_details/components/sidebar/sidebar_header.vue';
import JobRetryButton from '~/ci/job_details/components/sidebar/job_sidebar_retry_button.vue';
import getJobQuery from '~/ci/job_details/graphql/queries/get_job.query.graphql';
import { mockFullPath, mockId, mockJobResponse } from '../../mock_data';

Vue.use(VueApollo);

const defaultProvide = {
  projectPath: mockFullPath,
};

describe('Sidebar Header', () => {
  let wrapper;

  const createComponent = ({ options = {}, props = {}, restJob = {} } = {}) => {
    wrapper = shallowMountExtended(SidebarHeader, {
      propsData: {
        ...props,
        jobId: mockId,
        restJob: {
          status: {
            action: {
              confirmation_message: null,
            },
          },
          ...restJob,
        },
      },
      provide: {
        ...defaultProvide,
      },
      ...options,
    });
  };

  const createComponentWithApollo = ({ props = {}, restJob = {} } = {}) => {
    const getJobQueryResponse = jest.fn().mockResolvedValue(mockJobResponse);

    const requestHandlers = [[getJobQuery, getJobQueryResponse]];

    const apolloProvider = createMockApollo(requestHandlers);

    const options = {
      apolloProvider,
    };

    createComponent({
      props,
      restJob,
      options,
    });

    return waitForPromises();
  };

  const findCancelButton = () => wrapper.findByTestId('cancel-button');
  const findEraseButton = () => wrapper.findByTestId('job-log-erase-link');
  const findNewIssueButton = () => wrapper.findByTestId('job-new-issue');
  const findTerminalLink = () => wrapper.findByTestId('terminal-link');
  const findRetryButton = () => wrapper.findComponent(JobRetryButton);

  describe('when rendering contents', () => {
    it('does not render buttons with no paths', async () => {
      await createComponentWithApollo();
      expect(findCancelButton().exists()).toBe(false);
      expect(findEraseButton().exists()).toBe(false);
      expect(findRetryButton().exists()).toBe(false);
      expect(findNewIssueButton().exists()).toBe(false);
      expect(findTerminalLink().exists()).toBe(false);
    });

    it('renders a retry button with a path', async () => {
      await createComponentWithApollo({ restJob: { retry_path: 'retry/path' } });
      expect(findRetryButton().exists()).toBe(true);
    });

    it('renders a cancel button with a path', async () => {
      await createComponentWithApollo({ restJob: { cancel_path: 'cancel/path' } });
      expect(findCancelButton().exists()).toBe(true);
    });

    it('renders an erase button with a path', async () => {
      await createComponentWithApollo({ restJob: { erase_path: 'erase/path' } });
      expect(findEraseButton().exists()).toBe(true);
    });

    it('should render link to new issue', async () => {
      await createComponentWithApollo({ restJob: { new_issue_path: 'new/issue/path' } });
      expect(findNewIssueButton().attributes('href')).toBe('new/issue/path');
    });

    it('should render terminal link', async () => {
      await createComponentWithApollo({ restJob: { terminal_path: 'terminal/path' } });
      expect(findTerminalLink().attributes('href')).toBe('terminal/path');
    });
  });
});
