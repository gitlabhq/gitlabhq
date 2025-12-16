import Vue, { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import { createConfirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_action';
import ConfirmModal from '~/lib/utils/confirm_via_gl_modal/confirm_modal.vue';

const { bindInternalEventDocument } = useMockInternalEventsTracking();

const isVue3 = Vue.version.startsWith('3');

describe('confirmAction', () => {
  let wrapper;
  let confirActionPromise;
  let modal;

  const confirmAction = createConfirmAction({
    mountFn: (Component) => {
      wrapper = shallowMount(Component);

      return wrapper;
    },
    destroyFn: (instance) => {
      instance.destroy();
    },
  });

  const findConfirmModal = () => wrapper.findComponent(ConfirmModal);
  const getConfirmModalProps = () => {
    if (isVue3) {
      // It's not clear why Wrapper#props() isn't working for ConfirmModal
      // under VTU@2. We need to inspect its $attrs instead.
      return modal.vm.$attrs;
    }

    return modal.props();
  };

  const renderRootComponent = async (message, opts) => {
    confirActionPromise = confirmAction(message, opts);
    // Wait for dynamic import in implementation to resolve.
    await import('~/lib/utils/confirm_via_gl_modal/confirm_modal.vue');
    // Wait for root component to render.
    await nextTick();
    modal = findConfirmModal();
  };

  it('creates a ConfirmModal with message as slot', async () => {
    const message = 'Bonjour le monde!';
    await renderRootComponent(message);

    expect(modal.text()).toContain(message);
  });

  it('creates a ConfirmModal with props', async () => {
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
    expect(getConfirmModalProps()).toEqual(
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
        size: options.size,
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
    const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

    modal.vm.$emit('confirmed');

    expect(trackEventSpy).toHaveBeenCalledWith('unprotect_branch', {
      label: 'repository_settings',
    });
  });
});
