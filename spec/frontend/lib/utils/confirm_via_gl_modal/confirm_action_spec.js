import Vue, { nextTick } from 'vue';
import { createWrapper } from '@vue/test-utils';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_action';
import ConfirmModal from '~/lib/utils/confirm_via_gl_modal/confirm_modal.vue';

const originalMount = Vue.prototype.$mount;
const { bindInternalEventDocument } = useMockInternalEventsTracking();

describe('confirmAction', () => {
  let modalWrapper;
  let confirActionPromise;
  let modal;

  const findConfirmModal = () => modalWrapper.findComponent(ConfirmModal);
  const renderRootComponent = async (message, opts) => {
    confirActionPromise = confirmAction(message, opts);
    // We have to wait for two ticks here.
    // The first one is to wait for rendering of the root component
    // The second one to wait for rendering of the dynamically
    // loaded confirm-modal component
    await nextTick();
    await nextTick();
    modal = findConfirmModal();
  };
  const mockMount = (vm, el) => {
    originalMount.call(vm, el);
    modalWrapper = createWrapper(vm);
    return vm;
  };

  beforeEach(() => {
    setHTMLFixture('<div id="component"></div>');
    const el = document.getElementById('component');
    // We mock the implementation only once to make sure that we mock
    // it only for the root component in confirm_action.
    // Mounting other components (like confirm-modal) should not be affected with
    // this mock
    jest.spyOn(Vue.prototype, '$mount').mockImplementationOnce(function mock() {
      return mockMount(this, el);
    });
  });

  afterEach(() => {
    resetHTMLFixture();
    Vue.prototype.$mount.mockRestore();
    modalWrapper?.destroy();
    modal?.destroy();
    modal = null;
  });

  it('creats a ConfirmModal with message as slot', async () => {
    const message = 'Bonjour le monde!';
    await renderRootComponent(message);

    expect(modal.vm.$slots.default[0].text).toBe(message);
  });

  it('creats a ConfirmModal with props', async () => {
    const options = {
      primaryBtnText: 'primaryBtnText',
      primaryBtnVariant: 'info',
      secondaryBtnText: 'secondaryBtnText',
      secondaryBtnVariant: 'success',
      cancelBtnText: 'cancelBtnText',
      cancelBtnVariant: 'danger',
      modalHtmlMessage: '<strong>Hello</strong>',
      title: 'title',
      hideCancel: true,
      size: 'md',
    };
    await renderRootComponent('', options);
    expect(modal.props()).toEqual(
      expect.objectContaining({
        primaryText: options.primaryBtnText,
        primaryVariant: options.primaryBtnVariant,
        secondaryText: options.secondaryBtnText,
        secondaryVariant: options.secondaryBtnVariant,
        cancelText: options.cancelBtnText,
        cancelVariant: options.cancelBtnVariant,
        modalHtmlMessage: options.modalHtmlMessage,
        title: options.title,
        hideCancel: options.hideCancel,
        size: 'md',
      }),
    );
  });

  it('resolves promise when modal emit `closed`', async () => {
    await renderRootComponent('');

    modal.vm.$emit('closed');

    await expect(confirActionPromise).resolves.toBe(false);
  });

  it('confirms when modal emit `confirmed` before `closed`', async () => {
    await renderRootComponent('');

    modal.vm.$emit('confirmed');
    modal.vm.$emit('closed');

    await expect(confirActionPromise).resolves.toBe(true);
  });

  it('emits a tracking event when modal emit `confirmed` and event name is provided', async () => {
    const trackingEvent = {
      name: 'unprotect_branch',
      label: 'repository_settings',
    };
    await renderRootComponent('', { trackingEvent });
    const { trackEventSpy } = bindInternalEventDocument(modalWrapper.element);

    modal.vm.$emit('confirmed');

    expect(trackEventSpy).toHaveBeenCalledWith('unprotect_branch', {
      label: 'repository_settings',
    });
  });
});
