import { mount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import { GlLoadingIcon } from '@gitlab/ui';
import ErrorMessage from '~/ide/components/error_message.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('IDE error message component', () => {
  let wrapper;

  const setErrorMessageMock = jest.fn();
  const createComponent = messageProps => {
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
      localVue,
    });
  };

  beforeEach(() => {
    setErrorMessageMock.mockReset();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
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

    it('does not dispatch action when already loading', () => {
      findActionButton().trigger('click');
      actionMock.mockReset();
      return wrapper.vm.$nextTick(() => {
        findActionButton().trigger('click');

        return wrapper.vm.$nextTick().then(() => {
          expect(actionMock).not.toHaveBeenCalled();
        });
      });
    });

    it('shows loading icon when loading', () => {
      let resolveAction;
      actionMock.mockImplementation(
        () =>
          new Promise(resolve => {
            resolveAction = resolve;
          }),
      );
      findActionButton().trigger('click');

      return wrapper.vm.$nextTick(() => {
        expect(wrapper.find(GlLoadingIcon).isVisible()).toBe(true);
        resolveAction();
      });
    });

    it('hides loading icon when operation finishes', () => {
      findActionButton().trigger('click');
      return actionMock()
        .then(() => wrapper.vm.$nextTick())
        .then(() => {
          expect(wrapper.find(GlLoadingIcon).isVisible()).toBe(false);
        });
    });
  });
});
