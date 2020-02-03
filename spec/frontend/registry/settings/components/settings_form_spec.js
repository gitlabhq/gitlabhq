import { shallowMount } from '@vue/test-utils';
import Tracking from '~/tracking';
import component from '~/registry/settings/components/settings_form.vue';
import expirationPolicyForm from '~/registry/shared/components/expiration_policy_form.vue';
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

  const trackingPayload = {
    label: 'docker_container_retention_and_expiration_policies',
  };

  const findForm = () => wrapper.find(expirationPolicyForm);

  const mountComponent = () => {
    wrapper = shallowMount(component, {
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
    });

    describe('data binding', () => {
      it('v-model change update the settings property', () => {
        dispatchSpy.mockReturnValue();
        form.vm.$emit('input', 'foo');
        expect(dispatchSpy).toHaveBeenCalledWith('updateSettings', { settings: 'foo' });
      });
    });

    describe('form reset event', () => {
      it('calls the appropriate function', () => {
        dispatchSpy.mockReturnValue();
        form.vm.$emit('reset');
        expect(dispatchSpy).toHaveBeenCalledWith('resetSettings');
      });

      it('tracks the reset event', () => {
        dispatchSpy.mockReturnValue();
        form.vm.$emit('reset');
        expect(Tracking.event).toHaveBeenCalledWith(undefined, 'reset_form', trackingPayload);
      });
    });

    describe('form submit event ', () => {
      it('dispatches the saveSettings action', () => {
        dispatchSpy.mockResolvedValue();
        form.vm.$emit('submit');
        expect(dispatchSpy).toHaveBeenCalledWith('saveSettings');
      });

      it('tracks the submit event', () => {
        dispatchSpy.mockResolvedValue();
        form.vm.$emit('submit');
        expect(Tracking.event).toHaveBeenCalledWith(undefined, 'submit_form', trackingPayload);
      });

      it('show a success toast when submit succeed', () => {
        dispatchSpy.mockResolvedValue();
        form.vm.$emit('submit');
        return wrapper.vm.$nextTick().then(() => {
          expect(wrapper.vm.$toast.show).toHaveBeenCalledWith(UPDATE_SETTINGS_SUCCESS_MESSAGE, {
            type: 'success',
          });
        });
      });

      it('show an error toast when submit fails', () => {
        dispatchSpy.mockRejectedValue();
        form.vm.$emit('submit');
        return wrapper.vm.$nextTick().then(() => {
          expect(wrapper.vm.$toast.show).toHaveBeenCalledWith(UPDATE_SETTINGS_ERROR_MESSAGE, {
            type: 'error',
          });
        });
      });
    });
  });
});
