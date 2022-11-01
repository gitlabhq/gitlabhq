import { shallowMount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import JobRetryButton from '~/jobs/components/job/sidebar/job_sidebar_retry_button.vue';
import LegacySidebarHeader from '~/jobs/components/job/sidebar/legacy_sidebar_header.vue';
import createStore from '~/jobs/store';
import job, { failedJobStatus } from '../../mock_data';

describe('Legacy Sidebar Header', () => {
  let store;
  let wrapper;

  const findCancelButton = () => wrapper.findByTestId('cancel-button');
  const findRetryButton = () => wrapper.findComponent(JobRetryButton);
  const findEraseLink = () => wrapper.findByTestId('job-log-erase-link');

  const createWrapper = (props) => {
    store = createStore();

    wrapper = extendedWrapper(
      shallowMount(LegacySidebarHeader, {
        propsData: {
          job,
          ...props,
        },
        store,
      }),
    );
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when job log is erasable', () => {
    const path = '/root/ci-project/-/jobs/1447/erase';

    beforeEach(() => {
      createWrapper({
        erasePath: path,
      });
    });

    it('renders erase job link', () => {
      expect(findEraseLink().exists()).toBe(true);
    });

    it('erase job link has correct path', () => {
      expect(findEraseLink().attributes('href')).toBe(path);
    });
  });

  describe('when job log is not erasable', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('does not render erase button', () => {
      expect(findEraseLink().exists()).toBe(false);
    });
  });

  describe('when the job is retryable', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('should render the retry button', () => {
      expect(findRetryButton().props('href')).toBe(job.retry_path);
    });

    it('should have a different label when the job status is passed', () => {
      expect(findRetryButton().attributes('title')).toBe(
        LegacySidebarHeader.i18n.runAgainJobButtonLabel,
      );
    });
  });

  describe('when there is no retry path', () => {
    it('should not render a retry button', async () => {
      const copy = { ...job, retry_path: null };
      createWrapper({ job: copy });

      expect(findRetryButton().exists()).toBe(false);
    });
  });

  describe('when the job is cancelable', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('should render link to cancel job', () => {
      expect(findCancelButton().props('icon')).toBe('cancel');
      expect(findCancelButton().attributes('href')).toBe(job.cancel_path);
    });
  });

  describe('when the job is failed', () => {
    describe('retry button', () => {
      it('should have a different label when the job status is failed', () => {
        createWrapper({ job: { ...job, status: failedJobStatus } });

        expect(findRetryButton().attributes('title')).toBe(
          LegacySidebarHeader.i18n.retryJobButtonLabel,
        );
      });
    });
  });
});
