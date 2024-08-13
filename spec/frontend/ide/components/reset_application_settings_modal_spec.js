import MockAdapter from 'axios-mock-adapter';
import { GlAlert, GlModal } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';

import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_NO_CONTENT, HTTP_STATUS_BAD_REQUEST } from '~/lib/utils/http_status';
import ResetApplicationSettingsModal, {
  I18N_RESET_APPLICATION_SETTINGS_MODAL,
} from '~/ide/components/reset_application_settings_modal.vue';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { stubComponent } from 'helpers/stub_component';

const mockEvent = { preventDefault: jest.fn() };
const mockHide = jest.fn();
const MOCK_RESET_APPLICATION_SETTINGS_PATH = '/reset_application_settings_path';

describe('ResetApplicationSettingsModal', () => {
  useMockLocationHelper();

  let mockAxios;
  let wrapper;

  const findModal = () => wrapper.findComponent(GlModal);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const firePrimaryEvent = () => findModal().vm.$emit('primary', mockEvent);

  const createWrapper = () => {
    wrapper = mount(ResetApplicationSettingsModal, {
      propsData: {
        visible: true,
        resetApplicationSettingsPath: MOCK_RESET_APPLICATION_SETTINGS_PATH,
      },
      stubs: {
        GlModal: stubComponent(GlModal, {
          methods: {
            hide: mockHide,
          },
        }),
      },
    });
  };

  beforeEach(() => {
    mockAxios = new MockAdapter(axios);

    createWrapper();
  });

  afterEach(() => {
    mockAxios.restore();
  });

  it('renders modal with correct props', () => {
    const modal = findModal();

    expect(modal.props('modalId')).toBe('reset-application-settings-modal');
    expect(modal.props('title')).toEqual(I18N_RESET_APPLICATION_SETTINGS_MODAL.title);
    expect(modal.props('visible')).toBe(true);
  });

  describe('resetApplicationSetings', () => {
    it('makes request to reset application settings path', async () => {
      mockAxios.onPost(MOCK_RESET_APPLICATION_SETTINGS_PATH).reply(HTTP_STATUS_NO_CONTENT);

      firePrimaryEvent();
      await waitForPromises();
      await nextTick();

      expect(mockAxios.history.post.length).toBe(1);
      expect(mockAxios.history.post[0].url).toBe(MOCK_RESET_APPLICATION_SETTINGS_PATH);
    });

    describe('on success', () => {
      beforeEach(async () => {
        mockAxios.onPost(MOCK_RESET_APPLICATION_SETTINGS_PATH).reply(HTTP_STATUS_NO_CONTENT);

        firePrimaryEvent();
        await waitForPromises();
        await nextTick();
      });

      it('closes modal and reloads window upon successful reset', () => {
        expect(mockHide).toHaveBeenCalledTimes(1);
        expect(window.location.reload).toHaveBeenCalledTimes(1);
      });

      it('does not display error alert', () => {
        expect(findAlert().exists()).toBe(false);
      });
    });

    describe('on error', () => {
      beforeEach(async () => {
        mockAxios.onPost(MOCK_RESET_APPLICATION_SETTINGS_PATH).reply(HTTP_STATUS_BAD_REQUEST);

        firePrimaryEvent();
        await waitForPromises();
        await nextTick();
      });

      it('does not reload window upon error', () => {
        expect(window.location.reload).not.toHaveBeenCalled();
      });

      it('displays error alert', () => {
        const modal = findModal();
        const errorAlert = findAlert();

        expect(modal.props('visible')).toBe(true);
        expect(modal.props('actionPrimary').attributes.loading).toBe(false);
        expect(errorAlert.exists()).toBe(true);
        expect(errorAlert.text()).toBe(I18N_RESET_APPLICATION_SETTINGS_MODAL.errorMessage);
      });
    });
  });
});
