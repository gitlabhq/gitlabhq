import { nextTick } from 'vue';
import { mount } from '@vue/test-utils';
import { GlModal } from '@gitlab/ui';
import { TEST_HOST } from 'helpers/test_constants';
import axios from '~/lib/utils/axios_utils';
import { visitUrl } from '~/lib/utils/url_utility';
import CancelJobsModal from '~/ci/admin/jobs_table/components/cancel_jobs_modal.vue';
import { setVueErrorHandler } from '../../../../__helpers__/set_vue_error_handler';

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn(),
}));

describe('Cancel jobs modal', () => {
  const props = {
    url: `${TEST_HOST}/cancel_jobs_modal.vue/cancelAll`,
    modalId: 'cancel-jobs-modal',
  };
  let wrapper;

  beforeEach(() => {
    wrapper = mount(CancelJobsModal, { propsData: props });
  });

  describe('on submit', () => {
    it('cancels jobs and redirects to overview page', async () => {
      const responseURL = `${TEST_HOST}/cancel_jobs_modal.vue/jobs`;
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

      expect(visitUrl).toHaveBeenCalledWith(responseURL);
    });

    it('displays error if canceling jobs failed', async () => {
      const dummyError = new Error('canceling jobs failed');
      // TODO: We can't use axios-mock-adapter because our current version
      // does not support responseURL
      //
      // see https://gitlab.com/gitlab-org/gitlab/-/issues/375308 for details
      jest.spyOn(axios, 'post').mockImplementation((url) => {
        expect(url).toBe(props.url);
        return Promise.reject(dummyError);
      });

      setVueErrorHandler({ instance: wrapper.vm, handler: () => {} }); // silencing thrown error
      wrapper.findComponent(GlModal).vm.$emit('primary');
      await nextTick();

      expect(visitUrl).not.toHaveBeenCalled();
    });
  });
});
