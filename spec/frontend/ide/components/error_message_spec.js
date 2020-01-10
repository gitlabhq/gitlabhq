import { shallowMount, createLocalVue } from '@vue/test-utils';
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

    wrapper = shallowMount(ErrorMessage, {
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

  it('renders error message', () => {
    const text = 'error message';
    createComponent({ text });
    expect(wrapper.text()).toContain(text);
  });

  it('clears error message on click', () => {
    createComponent();
    wrapper.trigger('click');

    expect(setErrorMessageMock).toHaveBeenCalledWith(expect.any(Object), null, undefined);
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
      const button = wrapper.find('button');

      expect(button.exists()).toBe(true);
      expect(button.text()).toContain(message.actionText);
    });

    it('does not clear error message on click', () => {
      wrapper.trigger('click');

      expect(setErrorMessageMock).not.toHaveBeenCalled();
    });

    it('dispatches action', () => {
      wrapper.find('button').trigger('click');

      expect(actionMock).toHaveBeenCalledWith(message.actionPayload);
    });

    it('does not dispatch action when already loading', () => {
      wrapper.find('button').trigger('click');
      actionMock.mockReset();
      return wrapper.vm.$nextTick(() => {
        wrapper.find('button').trigger('click');

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
      wrapper.find('button').trigger('click');

      return wrapper.vm.$nextTick(() => {
        expect(wrapper.find(GlLoadingIcon).isVisible()).toBe(true);
        resolveAction();
      });
    });

    it('hides loading icon when operation finishes', () => {
      wrapper.find('button').trigger('click');
      return actionMock()
        .then(() => wrapper.vm.$nextTick())
        .then(() => {
          expect(wrapper.find(GlLoadingIcon).isVisible()).toBe(false);
        });
    });
  });
});
