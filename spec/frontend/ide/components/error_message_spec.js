import { GlLoadingIcon } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import ErrorMessage from '~/ide/components/error_message.vue';

Vue.use(Vuex);

describe('IDE error message component', () => {
  let wrapper;

  const setErrorMessageMock = jest.fn();
  const createComponent = (messageProps) => {
    const fakeStore = new Vuex.Store({
      actions: { setErrorMessage: setErrorMessageMock },
    });

    wrapper = mount(ErrorMessage, {
      propsData: {
        message: {
          text: 'some text',
          actionText: 'test action',
          actionPayload: 'testActionPayload',
          ...messageProps,
        },
      },
      store: fakeStore,
    });
  };

  beforeEach(() => {
    setErrorMessageMock.mockReset();
  });

  const findDismissButton = () => wrapper.find('button[aria-label=Dismiss]');
  const findActionButton = () => wrapper.find('button.gl-alert-action');

  it('renders error message', () => {
    const text = 'error message';
    createComponent({ text });
    expect(wrapper.text()).toContain(text);
  });

  it('clears error message on dismiss click', () => {
    createComponent();
    findDismissButton().trigger('click');

    expect(setErrorMessageMock).toHaveBeenCalledWith(expect.any(Object), null);
  });

  describe('with action', () => {
    let actionMock;

    const message = {
      actionText: 'test action',
      actionPayload: 'testActionPayload',
    };

    beforeEach(() => {
      actionMock = jest.fn().mockResolvedValue();
      createComponent({
        ...message,
        action: actionMock,
      });
    });

    it('renders action button', () => {
      const button = findActionButton();

      expect(button.exists()).toBe(true);
      expect(button.text()).toContain(message.actionText);
    });

    it('does not show dismiss button', () => {
      expect(findDismissButton().exists()).toBe(false);
    });

    it('dispatches action', () => {
      findActionButton().trigger('click');

      expect(actionMock).toHaveBeenCalledWith(message.actionPayload);
    });

    it('does not dispatch action when already loading', async () => {
      findActionButton().trigger('click');
      actionMock.mockReset();
      findActionButton().trigger('click');
      await nextTick();
      expect(actionMock).not.toHaveBeenCalled();
    });

    it('shows loading icon when loading', async () => {
      let resolveAction;
      actionMock.mockImplementation(
        () =>
          new Promise((resolve) => {
            resolveAction = resolve;
          }),
      );
      findActionButton().trigger('click');

      await nextTick();
      expect(wrapper.findComponent(GlLoadingIcon).isVisible()).toBe(true);
      resolveAction();
    });

    it('hides loading icon when operation finishes', async () => {
      findActionButton().trigger('click');
      await actionMock();
      await nextTick();
      expect(wrapper.findComponent(GlLoadingIcon).isVisible()).toBe(false);
    });
  });
});
