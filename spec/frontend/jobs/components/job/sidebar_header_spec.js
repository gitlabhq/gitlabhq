import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import SidebarHeader from '~/jobs/components/job/sidebar/sidebar_header.vue';
import JobRetryButton from '~/jobs/components/job/sidebar/job_sidebar_retry_button.vue';
import getJobQuery from '~/jobs/components/job/graphql/queries/get_job.query.graphql';
import { mockFullPath, mockId, mockJobResponse } from './mock_data';

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
        restJob,
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
  const findJobName = () => wrapper.findByTestId('job-name');
  const findRetryButton = () => wrapper.findComponent(JobRetryButton);

  describe('when rendering contents', () => {
    it('renders the correct job name', async () => {
      await createComponentWithApollo();
      expect(findJobName().text()).toBe(mockJobResponse.data.project.job.name);
    });

    it('does not render buttons with no paths', async () => {
      await createComponentWithApollo();
      expect(findCancelButton().exists()).toBe(false);
      expect(findEraseButton().exists()).toBe(false);
      expect(findRetryButton().exists()).toBe(false);
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
  });
});
