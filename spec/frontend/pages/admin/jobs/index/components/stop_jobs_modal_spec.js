import Vue, { nextTick } from 'vue';
import { mount } from '@vue/test-utils';
import { GlModal } from '@gitlab/ui';
import { TEST_HOST } from 'helpers/test_constants';
import axios from '~/lib/utils/axios_utils';
import { redirectTo } from '~/lib/utils/url_utility';
import StopJobsModal from '~/pages/admin/jobs/index/components/stop_jobs_modal.vue';

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  redirectTo: jest.fn(),
}));

describe('stop_jobs_modal.vue', () => {
  const props = {
    url: `${TEST_HOST}/stop_jobs_modal.vue/stopAll`,
  };
  let wrapper;

  beforeEach(() => {
    wrapper = mount(StopJobsModal, { propsData: props });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('on submit', () => {
    it('stops jobs and redirects to overview page', async () => {
      const responseURL = `${TEST_HOST}/stop_jobs_modal.vue/jobs`;
      // TODO: We can't use axios-mock-adapter because our current version
      // does not support responseURL
      //
      // see https://gitlab.com/gitlab-org/gitlab/-/issues/375308 for details
      jest.spyOn(axios, 'post').mockImplementation((url) => {
        expect(url).toBe(props.url);
        return Promise.resolve({
          request: {
            responseURL,
          },
        });
      });

      wrapper.findComponent(GlModal).vm.$emit('primary');
      await nextTick();

      expect(redirectTo).toHaveBeenCalledWith(responseURL);
    });

    it('displays error if stopping jobs failed', async () => {
      Vue.config.errorHandler = () => {}; // silencing thrown error

      const dummyError = new Error('stopping jobs failed');
      // TODO: We can't use axios-mock-adapter because our current version
      // does not support responseURL
      //
      // see https://gitlab.com/gitlab-org/gitlab/-/issues/375308 for details
      jest.spyOn(axios, 'post').mockImplementation((url) => {
        expect(url).toBe(props.url);
        return Promise.reject(dummyError);
      });

      wrapper.findComponent(GlModal).vm.$emit('primary');
      await nextTick();

      expect(redirectTo).not.toHaveBeenCalled();
    });
  });
});
