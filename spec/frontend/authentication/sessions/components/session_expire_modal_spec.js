import { GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import SessionExpireModal from '~/authentication/sessions/components/session_expire_modal.vue';
import { INTERVAL_SESSION_MODAL } from '~/authentication/sessions/constants';
import { visitUrl } from '~/lib/utils/url_utility';

jest.useFakeTimers();
jest.mock('~/lib/utils/url_utility');

describe('SessionExpireModal', () => {
  const message = 'Modal message';
  const sessionTimeout = 0;
  const signInUrl = 'http://gitlab.example.com/users/sign_in?redirect_to_referer=yes';
  const title = 'Modal title';
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(SessionExpireModal, {
      propsData: {
        message,
        sessionTimeout,
        signInUrl,
        title,
        ...props,
      },
    });
  };

  const findModal = () => wrapper.findComponent(GlModal);

  it('initially, it does not show the modal', () => {
    createComponent();

    expect(findModal().props()).toMatchObject({
      visible: false,
      title,
      actionPrimary: {
        text: 'Sign in',
      },
      actionCancel: {
        text: 'Cancel',
      },
    });
    expect(findModal().attributes()).toMatchObject({
      'aria-live': 'assertive',
    });
  });

  describe('when there is a expiring session', () => {
    it('shows the modal triggered by time elapsed', async () => {
      jest.spyOn(global, 'setInterval');
      jest.spyOn(global, 'clearInterval');
      createComponent();

      expect(setInterval).toHaveBeenCalledTimes(1);
      expect(setInterval).toHaveBeenCalledWith(expect.any(Function), INTERVAL_SESSION_MODAL);

      jest.advanceTimersByTime(INTERVAL_SESSION_MODAL);
      await nextTick();

      expect(findModal().props('visible')).toBe(true);
      expect(clearInterval).toHaveBeenCalledTimes(1);
      expect(clearInterval).toHaveBeenCalledWith(expect.any(Number));
    });

    it('shows the modal triggered by changevisibility event', async () => {
      jest.spyOn(document, 'addEventListener');
      jest.spyOn(document, 'removeEventListener');
      createComponent();

      nextTick();
      expect(document.addEventListener).toHaveBeenCalledTimes(1);
      expect(document.addEventListener).toHaveBeenCalledWith(
        'visibilitychange',
        expect.any(Function),
      );

      document.dispatchEvent(new Event('visibilitychange'));
      await nextTick();

      expect(findModal().props('visible')).toBe(true);
      expect(document.removeEventListener).toHaveBeenCalledTimes(1);
      expect(document.removeEventListener).toHaveBeenCalledWith(
        'visibilitychange',
        expect.any(Function),
      );
    });

    it('shows the correct modal content', async () => {
      createComponent();
      await nextTick();

      expect(findModal().text()).toBe(message);
    });

    it('triggers a refresh of the current page', () => {
      createComponent();

      findModal().vm.$emit('primary');
      expect(visitUrl).toHaveBeenCalledWith(signInUrl);
    });
  });
});
