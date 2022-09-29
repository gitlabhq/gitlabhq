import { GlModal, GlFormCheckbox } from '@gitlab/ui';
import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { initEmojiMock, clearEmojiMock } from 'helpers/emoji';
import * as UserApi from '~/api/user_api';
import EmojiPicker from '~/emoji/components/picker.vue';
import { createAlert } from '~/flash';
import stubChildren from 'helpers/stub_children';
import SetStatusModalWrapper from '~/set_status_modal/set_status_modal_wrapper.vue';
import { AVAILABILITY_STATUS } from '~/set_status_modal/constants';
import SetStatusForm from '~/set_status_modal/set_status_form.vue';

jest.mock('~/flash');

describe('SetStatusModalWrapper', () => {
  let wrapper;
  const $toast = {
    show: jest.fn(),
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
  const findClearStatusAtMessage = () => wrapper.find('[data-testid="clear-status-at-message"]');
  const getEmojiPicker = () => wrapper.findComponent(EmojiPickerStub);

  const initModal = async ({ mockOnUpdateSuccess = true, mockOnUpdateFailure = true } = {}) => {
    const modal = findModal();
    // mock internal emoji methods
    wrapper.vm.showEmojiMenu = jest.fn();
    wrapper.vm.hideEmojiMenu = jest.fn();
    if (mockOnUpdateSuccess) wrapper.vm.onUpdateSuccess = jest.fn();
    if (mockOnUpdateFailure) wrapper.vm.onUpdateFail = jest.fn();

    modal.vm.$emit('shown');
    await nextTick();
  };

  afterEach(() => {
    wrapper.destroy();
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

    it('does not display the clear status at message', () => {
      expect(findClearStatusAtMessage().exists()).toBe(false);
    });

    it('renders emoji picker dropdown with custom positioning', () => {
      expect(getEmojiPicker().props()).toMatchObject({
        right: false,
        boundary: 'viewport',
      });
    });

    it('passes emoji to `SetStatusForm`', async () => {
      await getEmojiPicker().vm.$emit('click', 'thumbsup');

      expect(wrapper.findComponent(SetStatusForm).props('emoji')).toBe('thumbsup');
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
    beforeEach(async () => {
      await initEmojiMock();
      wrapper = createComponent({ currentClearStatusAfter: '2021-01-01 00:00:00 UTC' });
      return initModal();
    });

    it('displays the clear status at message', () => {
      const clearStatusAtMessage = findClearStatusAtMessage();

      expect(clearStatusAtMessage.exists()).toBe(true);
      expect(clearStatusAtMessage.text()).toBe('Your status resets on 2021-01-01 00:00:00 UTC.');
    });
  });

  describe('update status', () => {
    describe('succeeds', () => {
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
        findModal().vm.$emit('primary');
        await nextTick();

        // set the availability status
        findAvailabilityCheckbox().vm.$emit('input', true);

        // set the currentClearStatusAfter to 30 minutes
        wrapper.find('[data-testid="thirtyMinutes"]').trigger('click');

        findModal().vm.$emit('primary');
        await nextTick();

        const commonParams = {
          emoji: defaultEmoji,
          message: defaultMessage,
        };

        expect(UserApi.updateUserStatus).toHaveBeenCalledTimes(2);
        expect(UserApi.updateUserStatus).toHaveBeenNthCalledWith(1, {
          availability: AVAILABILITY_STATUS.NOT_SET,
          clearStatusAfter: null,
          ...commonParams,
        });
        expect(UserApi.updateUserStatus).toHaveBeenNthCalledWith(2, {
          availability: AVAILABILITY_STATUS.BUSY,
          clearStatusAfter: '30_minutes',
          ...commonParams,
        });
      });

      it('calls the "onUpdateSuccess" handler', async () => {
        findModal().vm.$emit('primary');
        await nextTick();

        expect(wrapper.vm.onUpdateSuccess).toHaveBeenCalled();
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

      it('calls the "onUpdateFail" handler', async () => {
        findModal().vm.$emit('primary');
        await nextTick();

        expect(wrapper.vm.onUpdateFail).toHaveBeenCalled();
      });
    });

    describe('error message', () => {
      beforeEach(async () => {
        await initEmojiMock();
        wrapper = createComponent({ currentEmoji: '', currentMessage: '' });
        jest.spyOn(UserApi, 'updateUserStatus').mockRejectedValue();
        return initModal({ mockOnUpdateFailure: false });
      });

      it('flashes an error message', async () => {
        findModal().vm.$emit('primary');
        await nextTick();

        expect(createAlert).toHaveBeenCalledWith({
          message: "Sorry, we weren't able to set your status. Please try again later.",
        });
      });
    });
  });
});
