import { nextTick } from 'vue';
import { GlAlert, GlLoadingIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import Loader from '~/observability/components/loader/index.vue';
import { DEFAULT_TIMERS, CONTENT_STATE } from '~/observability/components/loader/constants';

describe('Loader component', () => {
  let wrapper;

  const findSpinner = () => wrapper.findComponent(GlLoadingIcon);

  const findContentWrapper = () => wrapper.findByTestId('content-wrapper');

  const findAlert = () => wrapper.findComponent(GlAlert);

  const mountComponent = ({ ...props } = {}) => {
    wrapper = shallowMountExtended(Loader, {
      propsData: props,
    });
  };

  describe('on mount', () => {
    beforeEach(() => {
      mountComponent();
    });

    describe('showing content', () => {
      it('shows the loader if content is not loaded within CONTENT_WAIT_MS', async () => {
        expect(findSpinner().exists()).toBe(false);
        expect(findContentWrapper().exists()).toBe(false);

        jest.advanceTimersByTime(DEFAULT_TIMERS.CONTENT_WAIT_MS);

        await nextTick();

        expect(findSpinner().exists()).toBe(true);
        expect(findContentWrapper().exists()).toBe(false);
      });

      it('does not show the loader if content loads within CONTENT_WAIT_MS', async () => {
        expect(findSpinner().exists()).toBe(false);
        expect(findContentWrapper().exists()).toBe(false);

        await wrapper.setProps({ contentState: CONTENT_STATE.LOADED });

        expect(findContentWrapper().exists()).toBe(true);
        expect(findSpinner().exists()).toBe(false);

        jest.advanceTimersByTime(DEFAULT_TIMERS.CONTENT_WAIT_MS);

        await nextTick();

        expect(findContentWrapper().exists()).toBe(true);
        expect(findSpinner().exists()).toBe(false);
      });

      it('hides the loader after content loads', async () => {
        jest.advanceTimersByTime(DEFAULT_TIMERS.CONTENT_WAIT_MS);

        await nextTick();

        expect(findSpinner().exists()).toBe(true);
        expect(findContentWrapper().exists()).toBe(false);

        await wrapper.setProps({ contentState: CONTENT_STATE.LOADED });

        expect(findContentWrapper().exists()).toBe(true);
        expect(findSpinner().exists()).toBe(false);
      });
    });

    describe('error handling', () => {
      it('shows the error dialog if content has not loaded within TIMEOUT_MS', async () => {
        expect(findAlert().exists()).toBe(false);
        jest.advanceTimersByTime(DEFAULT_TIMERS.TIMEOUT_MS);

        await nextTick();

        expect(findAlert().exists()).toBe(true);
        expect(findContentWrapper().exists()).toBe(false);
      });

      it('shows the error dialog if content fails to load', async () => {
        expect(findAlert().exists()).toBe(false);

        await wrapper.setProps({ contentState: 'error' });

        expect(findAlert().exists()).toBe(true);
        expect(findContentWrapper().exists()).toBe(false);
      });

      it('does not show the error dialog if content has loaded within TIMEOUT_MS', async () => {
        wrapper.setProps({ contentState: CONTENT_STATE.LOADED });
        jest.advanceTimersByTime(DEFAULT_TIMERS.TIMEOUT_MS);

        await nextTick();

        expect(findAlert().exists()).toBe(false);
        expect(findContentWrapper().exists()).toBe(true);
      });
    });
  });
});
