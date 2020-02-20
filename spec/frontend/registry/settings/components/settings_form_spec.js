import { shallowMount } from '@vue/test-utils';
import Tracking from '~/tracking';
import component from '~/registry/settings/components/settings_form.vue';
import expirationPolicyFields from '~/registry/shared/components/expiration_policy_fields.vue';
import { createStore } from '~/registry/settings/store/';
import {
  UPDATE_SETTINGS_ERROR_MESSAGE,
  UPDATE_SETTINGS_SUCCESS_MESSAGE,
} from '~/registry/shared/constants';
import { stringifiedFormOptions } from '../../shared/mock_data';

describe('Settings Form', () => {
  let wrapper;
  let store;
  let dispatchSpy;

  const GlLoadingIcon = { name: 'gl-loading-icon-stub', template: '<svg></svg>' };
  const GlCard = {
    name: 'gl-card-stub',
    template: `
  <div>
    <slot name="header"></slot>
    <slot></slot>
    <slot name="footer"></slot>
  </div>
  `,
  };

  const trackingPayload = {
    label: 'docker_container_retention_and_expiration_policies',
  };

  const findForm = () => wrapper.find({ ref: 'form-element' });
  const findFields = () => wrapper.find(expirationPolicyFields);
  const findCancelButton = () => wrapper.find({ ref: 'cancel-button' });
  const findSaveButton = () => wrapper.find({ ref: 'save-button' });
  const findLoadingIcon = (parent = wrapper) => parent.find(GlLoadingIcon);

  const mountComponent = () => {
    wrapper = shallowMount(component, {
      stubs: {
        GlCard,
        GlLoadingIcon,
      },
      mocks: {
        $toast: {
          show: jest.fn(),
        },
      },
      store,
    });
  };

  beforeEach(() => {
    store = createStore();
    store.dispatch('setInitialState', stringifiedFormOptions);
    dispatchSpy = jest.spyOn(store, 'dispatch');
    mountComponent();
    jest.spyOn(Tracking, 'event');
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('form', () => {
    let form;
    beforeEach(() => {
      form = findForm();
      dispatchSpy.mockReturnValue();
    });

    describe('data binding', () => {
      it('v-model change update the settings property', () => {
        findFields().vm.$emit('input', 'foo');
        expect(dispatchSpy).toHaveBeenCalledWith('updateSettings', { settings: 'foo' });
      });
    });

    describe('form reset event', () => {
      beforeEach(() => {
        form.trigger('reset');
      });
      it('calls the appropriate function', () => {
        expect(dispatchSpy).toHaveBeenCalledWith('resetSettings');
      });

      it('tracks the reset event', () => {
        expect(Tracking.event).toHaveBeenCalledWith(undefined, 'reset_form', trackingPayload);
      });
    });

    describe('form submit event ', () => {
      it('save has type submit', () => {
        mountComponent();
        expect(findSaveButton().attributes('type')).toBe('submit');
      });

      it('dispatches the saveSettings action', () => {
        dispatchSpy.mockResolvedValue();
        form.trigger('submit');
        expect(dispatchSpy).toHaveBeenCalledWith('saveSettings');
      });

      it('tracks the submit event', () => {
        dispatchSpy.mockResolvedValue();
        form.trigger('submit');
        expect(Tracking.event).toHaveBeenCalledWith(undefined, 'submit_form', trackingPayload);
      });

      it('show a success toast when submit succeed', () => {
        dispatchSpy.mockResolvedValue();
        form.trigger('submit');
        return wrapper.vm.$nextTick().then(() => {
          expect(wrapper.vm.$toast.show).toHaveBeenCalledWith(UPDATE_SETTINGS_SUCCESS_MESSAGE, {
            type: 'success',
          });
        });
      });

      it('show an error toast when submit fails', () => {
        dispatchSpy.mockRejectedValue();
        form.trigger('submit');
        return wrapper.vm.$nextTick().then(() => {
          expect(wrapper.vm.$toast.show).toHaveBeenCalledWith(UPDATE_SETTINGS_ERROR_MESSAGE, {
            type: 'error',
          });
        });
      });
    });
  });

  describe('form actions', () => {
    describe('cancel button', () => {
      beforeEach(() => {
        store.commit('SET_SETTINGS', { foo: 'bar' });
      });

      it('has type reset', () => {
        expect(findCancelButton().attributes('type')).toBe('reset');
      });

      it('is disabled when isEdited is false', () =>
        wrapper.vm.$nextTick().then(() => {
          expect(findCancelButton().attributes('disabled')).toBe('true');
        }));

      it('is disabled isLoading is true', () => {
        store.commit('TOGGLE_LOADING');
        store.commit('UPDATE_SETTINGS', { settings: { foo: 'baz' } });
        return wrapper.vm.$nextTick().then(() => {
          expect(findCancelButton().attributes('disabled')).toBe('true');
          store.commit('TOGGLE_LOADING');
        });
      });

      it('is enabled when isLoading is false and isEdited is true', () => {
        store.commit('UPDATE_SETTINGS', { settings: { foo: 'baz' } });
        return wrapper.vm.$nextTick().then(() => {
          expect(findCancelButton().attributes('disabled')).toBe(undefined);
        });
      });
    });

    describe('when isLoading is true', () => {
      beforeEach(() => {
        store.commit('TOGGLE_LOADING');
      });
      afterEach(() => {
        store.commit('TOGGLE_LOADING');
      });

      it('submit button is disabled and shows a spinner', () => {
        const button = findSaveButton();
        expect(button.attributes('disabled')).toBeTruthy();
        expect(findLoadingIcon(button).exists()).toBe(true);
      });
    });
  });
});
