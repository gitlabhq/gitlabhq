import { shallowMount } from '@vue/test-utils';
import Tracking from '~/tracking';
import component from '~/registry/settings/components/settings_form.vue';
import expirationPolicyFields from '~/registry/shared/components/expiration_policy_fields.vue';
import { createStore } from '~/registry/settings/store/';
import {
  UPDATE_SETTINGS_ERROR_MESSAGE,
  UPDATE_SETTINGS_SUCCESS_MESSAGE,
} from '~/registry/shared/constants';
import waitForPromises from 'helpers/wait_for_promises';
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

  const mountComponent = (data = {}) => {
    wrapper = shallowMount(component, {
      stubs: {
        GlCard,
        GlLoadingIcon,
      },
      data() {
        return {
          ...data,
        };
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
    jest.spyOn(Tracking, 'event');
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('data binding', () => {
    it('v-model change update the settings property', () => {
      mountComponent();
      findFields().vm.$emit('input', { newValue: 'foo' });
      expect(dispatchSpy).toHaveBeenCalledWith('updateSettings', { settings: 'foo' });
    });

    it('v-model change update the api error property', () => {
      const apiErrors = { baz: 'bar' };
      mountComponent({ apiErrors });
      expect(findFields().props('apiErrors')).toEqual(apiErrors);
      findFields().vm.$emit('input', { newValue: 'foo', modified: 'baz' });
      expect(findFields().props('apiErrors')).toEqual({});
    });
  });

  describe('form', () => {
    let form;
    beforeEach(() => {
      mountComponent();
      form = findForm();
      dispatchSpy.mockReturnValue();
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

      it('show a success toast when submit succeed', async () => {
        dispatchSpy.mockResolvedValue();
        form.trigger('submit');
        await waitForPromises();
        expect(wrapper.vm.$toast.show).toHaveBeenCalledWith(UPDATE_SETTINGS_SUCCESS_MESSAGE, {
          type: 'success',
        });
      });

      describe('when submit fails', () => {
        it('shows an error', async () => {
          dispatchSpy.mockRejectedValue({ response: {} });
          form.trigger('submit');
          await waitForPromises();
          expect(wrapper.vm.$toast.show).toHaveBeenCalledWith(UPDATE_SETTINGS_ERROR_MESSAGE, {
            type: 'error',
          });
        });

        it('parses the error messages', async () => {
          dispatchSpy.mockRejectedValue({
            response: {
              data: {
                message: {
                  foo: 'bar',
                  'container_expiration_policy.name': ['baz'],
                },
              },
            },
          });
          form.trigger('submit');
          await waitForPromises();
          expect(findFields().props('apiErrors')).toEqual({ name: 'baz' });
        });
      });
    });
  });

  describe('form actions', () => {
    describe('cancel button', () => {
      beforeEach(() => {
        store.commit('SET_SETTINGS', { foo: 'bar' });
        mountComponent();
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
        mountComponent();
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
