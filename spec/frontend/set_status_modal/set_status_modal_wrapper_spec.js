import { GlModal, GlFormCheckbox } from '@gitlab/ui';
import { nextTick } from 'vue';
import { createWrapper } from '@vue/test-utils';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { useFakeDate } from 'helpers/fake_date';
import { initEmojiMock, clearEmojiMock } from 'helpers/emoji';
import * as UserApi from '~/api/user_api';
import EmojiPicker from '~/emoji/components/picker.vue';
import { createAlert } from '~/alert';
import stubChildren from 'helpers/stub_children';
import SetStatusModalWrapper from '~/set_status_modal/set_status_modal_wrapper.vue';
import { AVAILABILITY_STATUS } from '~/set_status_modal/constants';
import SetStatusForm from '~/set_status_modal/set_status_form.vue';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';
import { BV_HIDE_MODAL } from '~/lib/utils/constants';
import { EMOJI_THUMBS_UP } from '~/emoji/constants';

jest.mock('~/alert');

describe('SetStatusModalWrapper', () => {
  let wrapper;
  const mockToastShow = jest.fn();

  const $toast = {
    show: mockToastShow,
  };

  const defaultEmoji = 'speech_balloon';
  const defaultMessage = "They're comin' in too fast!";

  const defaultProps = {
    currentEmoji: defaultEmoji,
    currentMessage: defaultMessage,
    defaultEmoji,
  };

  const EmojiPickerStub = {
    props: EmojiPicker.props,
    template: '<div></div>',
  };

  const createComponent = (props = {}) => {
    return mountExtended(SetStatusModalWrapper, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: {
        ...stubChildren(SetStatusModalWrapper),
        GlFormInput: false,
        GlFormInputGroup: false,
        SetStatusForm: false,
        EmojiPicker: EmojiPickerStub,
      },
      mocks: {
        $toast,
      },
    });
  };

  const findModal = () => wrapper.findComponent(GlModal);
  const findMessageField = () =>
    wrapper.findByPlaceholderText(SetStatusForm.i18n.statusMessagePlaceholder);
  const findClearStatusButton = () => wrapper.find('.js-clear-user-status-button');
  const findAvailabilityCheckbox = () => wrapper.findComponent(GlFormCheckbox);
  const getEmojiPicker = () => wrapper.findComponent(EmojiPickerStub);
  const initModal = () => findModal().vm.$emit('shown');

  afterEach(() => {
    clearEmojiMock();
  });

  describe('with minimum props', () => {
    beforeEach(async () => {
      await initEmojiMock();
      wrapper = createComponent();
      return initModal();
    });

    it('sets the message field', () => {
      const field = findMessageField();
      expect(field.exists()).toBe(true);
      expect(field.element.value).toBe(defaultMessage);
    });

    it('sets the availability field to false', () => {
      const field = findAvailabilityCheckbox();
      expect(field.exists()).toBe(true);
      expect(field.element.checked).toBeUndefined();
    });

    it('has a clear status button', () => {
      expect(findClearStatusButton().exists()).toBe(true);
    });

    it('displays the clear status at dropdown', () => {
      expect(wrapper.find('[data-testid="clear-status-at-dropdown"]').exists()).toBe(true);
    });

    it('renders emoji picker dropdown with custom positioning', () => {
      expect(getEmojiPicker().props()).toMatchObject({
        right: false,
      });
    });

    it('passes emoji to `SetStatusForm`', async () => {
      await getEmojiPicker().vm.$emit('click', EMOJI_THUMBS_UP);

      expect(wrapper.findComponent(SetStatusForm).props('emoji')).toBe(EMOJI_THUMBS_UP);
    });
  });

  describe('with no currentMessage set', () => {
    beforeEach(async () => {
      await initEmojiMock();
      wrapper = createComponent({ currentMessage: '' });
      return initModal();
    });

    it('does not set the message field', () => {
      expect(findMessageField().element.value).toBe('');
    });

    it('hides the clear status button', () => {
      expect(findClearStatusButton().exists()).toBe(false);
    });
  });

  describe('with currentClearStatusAfter set', () => {
    useFakeDate(2022, 11, 5);

    beforeEach(async () => {
      await initEmojiMock();
      wrapper = createComponent({ currentClearStatusAfter: '2022-12-06T11:00:00Z' });
      return initModal();
    });

    it('displays date and time that status will expire in dropdown toggle button', () => {
      expect(wrapper.findByRole('button', { name: 'Dec 6, 2022, 11:00 AM' }).exists()).toBe(true);
    });
  });

  describe('update status', () => {
    describe('succeeds', () => {
      useMockLocationHelper();

      beforeEach(async () => {
        await initEmojiMock();
        wrapper = createComponent();
        await initModal();

        jest.spyOn(UserApi, 'updateUserStatus').mockResolvedValue();
      });

      it('clicking "removeStatus" clears the emoji and message fields', async () => {
        findModal().vm.$emit('secondary');
        await nextTick();

        expect(findMessageField().element.value).toBe('');
      });

      it('clicking "setStatus" submits the user status', async () => {
        // set the availability status
        findAvailabilityCheckbox().vm.$emit('input', true);

        // set the currentClearStatusAfter to 30 minutes
        await wrapper.find('[data-testid="listbox-item-thirtyMinutes"]').trigger('click');

        findModal().vm.$emit('primary');
        await nextTick();

        expect(UserApi.updateUserStatus).toHaveBeenCalledWith({
          availability: AVAILABILITY_STATUS.BUSY,
          clearStatusAfter: '30_minutes',
          emoji: defaultEmoji,
          message: defaultMessage,
        });
      });

      describe('when `Clear status after` field has not been set', () => {
        it('does not include `clearStatusAfter` in API request', async () => {
          findModal().vm.$emit('primary');
          await nextTick();

          expect(UserApi.updateUserStatus).toHaveBeenCalledWith({
            availability: AVAILABILITY_STATUS.NOT_SET,
            emoji: defaultEmoji,
            message: defaultMessage,
          });
        });
      });

      it('displays a toast message and reloads window', async () => {
        findModal().vm.$emit('primary');
        await nextTick();

        expect(mockToastShow).toHaveBeenCalledWith('Status updated');
        expect(window.location.reload).toHaveBeenCalled();
      });

      it('closes modal', async () => {
        const rootWrapper = createWrapper(wrapper.vm.$root);

        findModal().vm.$emit('primary');
        await nextTick();

        expect(rootWrapper.emitted(BV_HIDE_MODAL)).toEqual([['set-user-status-modal']]);
      });
    });

    describe('success message', () => {
      beforeEach(async () => {
        await initEmojiMock();
        wrapper = createComponent({ currentEmoji: '', currentMessage: '' });
        jest.spyOn(UserApi, 'updateUserStatus').mockResolvedValue();
        return initModal({ mockOnUpdateSuccess: false });
      });

      it('displays a toast success message', async () => {
        findModal().vm.$emit('primary');
        await nextTick();

        expect($toast.show).toHaveBeenCalledWith('Status updated');
      });
    });

    describe('with errors', () => {
      beforeEach(async () => {
        await initEmojiMock();
        wrapper = createComponent();
        await initModal();

        jest.spyOn(UserApi, 'updateUserStatus').mockRejectedValue();
      });

      it('displays an error alert', async () => {
        findModal().vm.$emit('primary');
        await nextTick();

        expect(createAlert).toHaveBeenCalledWith({
          message: "Sorry, we weren't able to set your status. Please try again later.",
        });
      });

      it('closes modal', async () => {
        const rootWrapper = createWrapper(wrapper.vm.$root);

        findModal().vm.$emit('primary');
        await nextTick();

        expect(rootWrapper.emitted(BV_HIDE_MODAL)).toEqual([['set-user-status-modal']]);
      });
    });

    describe('error message', () => {
      beforeEach(async () => {
        await initEmojiMock();
        wrapper = createComponent({ currentEmoji: '', currentMessage: '' });
        jest.spyOn(UserApi, 'updateUserStatus').mockRejectedValue();
        return initModal({ mockOnUpdateFailure: false });
      });

      it('alerts an error message', async () => {
        findModal().vm.$emit('primary');
        await nextTick();

        expect(createAlert).toHaveBeenCalledWith({
          message: "Sorry, we weren't able to set your status. Please try again later.",
        });
      });
    });
  });
});
