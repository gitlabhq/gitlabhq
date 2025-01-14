import { GlButton, GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert, VARIANT_SUCCESS, VARIANT_WARNING } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import OAuthSecret from '~/oauth_application/components/oauth_secret.vue';
import {
  RENEW_SECRET_FAILURE,
  RENEW_SECRET_SUCCESS,
  WARNING_NO_SECRET,
} from '~/oauth_application/constants';
import InputCopyToggleVisibility from '~/vue_shared/components/input_copy_toggle_visibility/input_copy_toggle_visibility.vue';

jest.mock('~/alert');
const mockEvent = { preventDefault: jest.fn() };

describe('OAuthSecret', () => {
  let wrapper;
  const renewPath = '/applications/1/renew';

  const createComponent = (provide = {}) => {
    wrapper = shallowMount(OAuthSecret, {
      provide: {
        initialSecret: undefined,
        renewPath,
        ...provide,
      },
    });
  };

  const findInputCopyToggleVisibility = () => wrapper.findComponent(InputCopyToggleVisibility);
  const findRenewSecretButton = () => wrapper.findComponent(GlButton);
  const findModal = () => wrapper.findComponent(GlModal);

  describe('when secret is provided', () => {
    const initialSecret = 'my secret';
    beforeEach(() => {
      createComponent({ initialSecret });
    });

    it('shows the masked secret', () => {
      expect(findInputCopyToggleVisibility().props('value')).toBe(initialSecret);
    });

    it('shows the renew secret button', () => {
      expect(findRenewSecretButton().exists()).toBe(true);
    });

    it('renders secret in readonly input', () => {
      expect(findInputCopyToggleVisibility().props('readonly')).toBe(true);
    });
  });

  describe('when secret is not provided', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows an alert', () => {
      expect(createAlert).toHaveBeenCalledWith({
        message: WARNING_NO_SECRET,
        variant: VARIANT_WARNING,
      });
    });

    it('shows the renew secret button', () => {
      expect(findRenewSecretButton().exists()).toBe(true);
    });

    describe('when renew secret button is selected', () => {
      beforeEach(() => {
        createComponent();
        findRenewSecretButton().vm.$emit('click');
      });

      it('shows a modal', () => {
        expect(findModal().props('visible')).toBe(true);
      });

      describe('when secret renewal succeeds', () => {
        const initialSecret = 'my secret';

        beforeEach(async () => {
          const mockAxios = new MockAdapter(axios);
          mockAxios.onPut().reply(HTTP_STATUS_OK, { secret: initialSecret });
          findModal().vm.$emit('primary', mockEvent);
          await waitForPromises();
        });

        it('shows an alert', () => {
          expect(createAlert).toHaveBeenCalledWith({
            message: RENEW_SECRET_SUCCESS,
            variant: VARIANT_SUCCESS,
          });
        });

        it('shows the new secret', () => {
          expect(findInputCopyToggleVisibility().props('value')).toBe(initialSecret);
        });
      });

      describe('when secret renewal fails', () => {
        beforeEach(async () => {
          const mockAxios = new MockAdapter(axios);
          mockAxios.onPut().reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
          findModal().vm.$emit('primary', mockEvent);
          await waitForPromises();
        });

        it('creates an alert', () => {
          expect(createAlert).toHaveBeenCalledWith({
            message: RENEW_SECRET_FAILURE,
          });
        });
      });
    });
  });
});
