import { GlButton, GlForm } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import mockTimezones from 'test_fixtures/timezones/full.json';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';

import axios from '~/lib/utils/axios_utils';
import ProfileEditApp from '~/profile/edit/components/profile_edit_app.vue';
import UserAvatar from '~/profile/edit/components/user_avatar.vue';
import SetStatusForm from '~/set_status_modal/set_status_form.vue';
import TimezoneDropdown from '~/vue_shared/components/timezone_dropdown/timezone_dropdown.vue';
import { VARIANT_DANGER, VARIANT_INFO, createAlert } from '~/alert';
import { AVAILABILITY_STATUS } from '~/set_status_modal/constants';
import { timeRanges } from '~/vue_shared/constants';
import { HTTP_STATUS_OK, HTTP_STATUS_INTERNAL_SERVER_ERROR } from '~/lib/utils/http_status';

jest.mock('~/alert');
jest.mock('~/lib/utils/file_utility', () => ({
  readFileAsDataURL: jest.fn().mockResolvedValue(),
}));

const [oneMinute, oneHour] = timeRanges;
const defaultProvide = {
  currentEmoji: 'basketball',
  currentMessage: 'Foo bar',
  currentAvailability: AVAILABILITY_STATUS.NOT_SET,
  defaultEmoji: 'speech_balloon',
  currentClearStatusAfter: oneMinute.shortcut,
  timezones: mockTimezones,
  userTimezone: '',
};

describe('Profile Edit App', () => {
  let wrapper;
  let mockAxios;

  const mockAvatarBlob = new Blob([''], { type: 'image/png' });

  const mockAvatarFile = new File([mockAvatarBlob], 'avatar.png', { type: mockAvatarBlob.type });

  const stubbedProfilePath = '/profile/edit';
  const stubbedUserPath = '/user/test';
  const successMessage = 'Profile was successfully updated.';

  const createComponent = () => {
    wrapper = shallowMountExtended(ProfileEditApp, {
      propsData: {
        profilePath: stubbedProfilePath,
        userPath: stubbedUserPath,
      },
      provide: defaultProvide,
    });
  };

  beforeEach(() => {
    mockAxios = new MockAdapter(axios);

    createComponent();
  });

  const findForm = () => wrapper.findComponent(GlForm);
  const findButtons = () => wrapper.findAllComponents(GlButton);
  const findAvatar = () => wrapper.findComponent(UserAvatar);
  const findSetStatusForm = () => wrapper.findComponent(SetStatusForm);
  const findTimezoneDropdown = () => wrapper.findComponent(TimezoneDropdown);
  const submitForm = () => findForm().vm.$emit('submit', new Event('submit'));
  const setAvatar = () => findAvatar().vm.$emit('blob-change', mockAvatarFile);
  const setStatus = () => {
    const setStatusForm = findSetStatusForm();

    setStatusForm.vm.$emit('message-input', 'Foo bar baz');
    setStatusForm.vm.$emit('emoji-click', 'baseball');
    setStatusForm.vm.$emit('clear-status-after-click', oneHour);
    setStatusForm.vm.$emit('availability-input', true);
  };
  const setTimezone = (index = 0) => {
    const timezoneForm = findTimezoneDropdown();

    timezoneForm.vm.$emit('input', mockTimezones[index]);
  };

  it('renders the form for users to interact with', () => {
    const form = findForm();
    const buttons = findButtons();

    expect(form.exists()).toBe(true);
    expect(buttons).toHaveLength(2);

    expect(wrapper.findByTestId('cancel-edit-button').attributes('href')).toBe(stubbedUserPath);
  });

  it('renders `SetStatusForm` component and passes correct props', () => {
    expect(findSetStatusForm().props()).toMatchObject({
      defaultEmoji: defaultProvide.defaultEmoji,
      emoji: defaultProvide.currentEmoji,
      message: defaultProvide.currentMessage,
      availability: false,
      clearStatusAfter: null,
      currentClearStatusAfter: defaultProvide.currentClearStatusAfter,
    });
  });

  it('renders `TimezoneForm` component and passes correct props', () => {
    expect(findTimezoneDropdown().props()).toMatchObject({
      timezoneData: mockTimezones,
      value: '',
    });
  });

  describe('when form submit request is successful', () => {
    it('shows success alert', async () => {
      mockAxios.onPut(stubbedProfilePath).reply(HTTP_STATUS_OK, {
        message: successMessage,
      });

      submitForm();
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({ message: successMessage, variant: VARIANT_INFO });
    });

    it('syncs header avatars', async () => {
      jest.spyOn(document, 'dispatchEvent');
      jest.spyOn(URL, 'createObjectURL');
      mockAxios.onPut(stubbedProfilePath).reply(HTTP_STATUS_OK, {
        message: successMessage,
      });

      setAvatar();
      submitForm();

      await waitForPromises();

      expect(URL.createObjectURL).toHaveBeenCalledWith(mockAvatarFile);
      expect(document.dispatchEvent).toHaveBeenCalledWith(new CustomEvent('userAvatar:update'));
    });

    it('contains changes from the status form', async () => {
      mockAxios.onPut(stubbedProfilePath).reply(HTTP_STATUS_OK, {
        message: successMessage,
      });

      setStatus();
      submitForm();

      await waitForPromises();
      const axiosRequestData = mockAxios.history.put[0].data;

      expect(axiosRequestData.get('user[status][emoji]')).toBe('baseball');
      expect(axiosRequestData.get('user[status][clear_status_after]')).toBe(oneHour.shortcut);
      expect(axiosRequestData.get('user[status][message]')).toBe('Foo bar baz');
      expect(axiosRequestData.get('user[status][availability]')).toBe(AVAILABILITY_STATUS.BUSY);
    });

    it('contains changes from timezone form', async () => {
      mockAxios.onPut(stubbedProfilePath).reply(HTTP_STATUS_OK, {
        message: successMessage,
      });
      const selectedTimezoneIndex = 2;
      setTimezone(selectedTimezoneIndex);
      submitForm();

      await waitForPromises();
      const axiosRequestData = mockAxios.history.put[0].data;
      expect(findTimezoneDropdown().props('value')).toBe(
        mockTimezones[selectedTimezoneIndex].identifier,
      );

      expect(axiosRequestData.get('user[timezone]')).toBe(
        mockTimezones[selectedTimezoneIndex].identifier,
      );
    });

    describe('when clear status after has not been changed', () => {
      it('does not include it in the API request', async () => {
        mockAxios.onPut(stubbedProfilePath).reply(HTTP_STATUS_OK, {
          message: successMessage,
        });

        submitForm();

        await waitForPromises();
        const axiosRequestData = mockAxios.history.put[0].data;

        expect(axiosRequestData.get('user[status][emoji]')).toBe(defaultProvide.currentEmoji);
        expect(axiosRequestData.get('user[status][clear_status_after]')).toBe(null);
        expect(axiosRequestData.get('user[status][message]')).toBe(defaultProvide.currentMessage);
        expect(axiosRequestData.get('user[status][availability]')).toBe(
          AVAILABILITY_STATUS.NOT_SET,
        );
      });
    });
  });

  describe('when form submit request is not successful', () => {
    it('shows error alert', async () => {
      mockAxios.onPut(stubbedProfilePath).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);

      submitForm();
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith(
        expect.objectContaining({ variant: VARIANT_DANGER }),
      );
    });
  });

  it('submits API request with avatar file', async () => {
    mockAxios.onPut(stubbedProfilePath).reply(HTTP_STATUS_OK);

    setAvatar();
    submitForm();

    await waitForPromises();

    const axiosRequestData = mockAxios.history.put[0].data;

    expect(axiosRequestData.get('user[avatar]')).toEqual(mockAvatarFile);
  });
});
