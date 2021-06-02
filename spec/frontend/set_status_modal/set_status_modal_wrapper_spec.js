import { GlModal, GlFormCheckbox } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { initEmojiMock } from 'helpers/emoji';
import * as UserApi from '~/api/user_api';
import EmojiPicker from '~/emoji/components/picker.vue';
import createFlash from '~/flash';
import SetStatusModalWrapper, {
  AVAILABILITY_STATUS,
} from '~/set_status_modal/set_status_modal_wrapper.vue';

jest.mock('~/flash');

describe('SetStatusModalWrapper', () => {
  let wrapper;
  let mockEmoji;
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

  const createComponent = (props = {}, improvedEmojiPicker = false) => {
    return shallowMount(SetStatusModalWrapper, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      mocks: {
        $toast,
      },
      provide: {
        glFeatures: { improvedEmojiPicker },
      },
    });
  };

  const findModal = () => wrapper.find(GlModal);
  const findFormField = (field) => wrapper.find(`[name="user[status][${field}]"]`);
  const findClearStatusButton = () => wrapper.find('.js-clear-user-status-button');
  const findNoEmojiPlaceholder = () => wrapper.find('.js-no-emoji-placeholder');
  const findToggleEmojiButton = () => wrapper.find('.js-toggle-emoji-menu');
  const findAvailabilityCheckbox = () => wrapper.find(GlFormCheckbox);
  const findClearStatusAtMessage = () => wrapper.find('[data-testid="clear-status-at-message"]');

  const initModal = ({ mockOnUpdateSuccess = true, mockOnUpdateFailure = true } = {}) => {
    const modal = findModal();
    // mock internal emoji methods
    wrapper.vm.showEmojiMenu = jest.fn();
    wrapper.vm.hideEmojiMenu = jest.fn();
    if (mockOnUpdateSuccess) wrapper.vm.onUpdateSuccess = jest.fn();
    if (mockOnUpdateFailure) wrapper.vm.onUpdateFail = jest.fn();

    modal.vm.$emit('shown');
    return wrapper.vm.$nextTick();
  };

  afterEach(() => {
    wrapper.destroy();
    mockEmoji.restore();
  });

  describe('with minimum props', () => {
    beforeEach(async () => {
      mockEmoji = await initEmojiMock();
      wrapper = createComponent();
      return initModal();
    });

    it('sets the hidden status emoji field', () => {
      const field = findFormField('emoji');
      expect(field.exists()).toBe(true);
      expect(field.element.value).toBe(defaultEmoji);
    });

    it('sets the message field', () => {
      const field = findFormField('message');
      expect(field.exists()).toBe(true);
      expect(field.element.value).toBe(defaultMessage);
    });

    it('sets the availability field to false', () => {
      const field = findAvailabilityCheckbox();
      expect(field.exists()).toBe(true);
      expect(field.element.checked).toBeUndefined();
    });

    it('has a clear status button', () => {
      expect(findClearStatusButton().isVisible()).toBe(true);
    });

    it('clicking the toggle emoji button displays the emoji list', () => {
      expect(wrapper.vm.showEmojiMenu).not.toHaveBeenCalled();
      findToggleEmojiButton().trigger('click');
      expect(wrapper.vm.showEmojiMenu).toHaveBeenCalled();
    });

    it('displays the clear status at dropdown', () => {
      expect(wrapper.find('[data-testid="clear-status-at-dropdown"]').exists()).toBe(true);
    });

    it('does not display the clear status at message', () => {
      expect(findClearStatusAtMessage().exists()).toBe(false);
    });
  });

  describe('improvedEmojiPicker is true', () => {
    beforeEach(async () => {
      mockEmoji = await initEmojiMock();
      wrapper = createComponent({}, true);
      return initModal();
    });

    it('sets emojiTag when clicking in emoji picker', async () => {
      await wrapper.findComponent(EmojiPicker).vm.$emit('click', 'thumbsup');

      expect(wrapper.vm.emojiTag).toContain('data-name="thumbsup"');
    });
  });

  describe('with no currentMessage set', () => {
    beforeEach(async () => {
      mockEmoji = await initEmojiMock();
      wrapper = createComponent({ currentMessage: '' });
      return initModal();
    });

    it('does not set the message field', () => {
      expect(findFormField('message').element.value).toBe('');
    });

    it('hides the clear status button', () => {
      expect(findClearStatusButton().isVisible()).toBe(false);
    });

    it('shows the placeholder emoji', () => {
      expect(findNoEmojiPlaceholder().isVisible()).toBe(true);
    });
  });

  describe('with no currentEmoji set', () => {
    beforeEach(async () => {
      mockEmoji = await initEmojiMock();
      wrapper = createComponent({ currentEmoji: '' });
      return initModal();
    });

    it('does not set the hidden status emoji field', () => {
      expect(findFormField('emoji').element.value).toBe('');
    });

    it('hides the placeholder emoji', () => {
      expect(findNoEmojiPlaceholder().isVisible()).toBe(false);
    });

    describe('with no currentMessage set', () => {
      beforeEach(async () => {
        mockEmoji = await initEmojiMock();
        wrapper = createComponent({ currentEmoji: '', currentMessage: '' });
        return initModal();
      });

      it('shows the placeholder emoji', () => {
        expect(findNoEmojiPlaceholder().isVisible()).toBe(true);
      });
    });
  });

  describe('with currentClearStatusAfter set', () => {
    beforeEach(async () => {
      mockEmoji = await initEmojiMock();
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
        mockEmoji = await initEmojiMock();
        wrapper = createComponent();
        await initModal();

        jest.spyOn(UserApi, 'updateUserStatus').mockResolvedValue();
      });

      it('clicking "removeStatus" clears the emoji and message fields', async () => {
        findModal().vm.$emit('cancel');
        await wrapper.vm.$nextTick();

        expect(findFormField('message').element.value).toBe('');
        expect(findFormField('emoji').element.value).toBe('');
      });

      it('clicking "setStatus" submits the user status', async () => {
        findModal().vm.$emit('ok');
        await wrapper.vm.$nextTick();

        // set the availability status
        findAvailabilityCheckbox().vm.$emit('input', true);

        // set the currentClearStatusAfter to 30 minutes
        wrapper.find('[data-testid="thirtyMinutes"]').vm.$emit('click');

        findModal().vm.$emit('ok');
        await wrapper.vm.$nextTick();

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
        findModal().vm.$emit('ok');
        await wrapper.vm.$nextTick();

        expect(wrapper.vm.onUpdateSuccess).toHaveBeenCalled();
      });
    });

    describe('success message', () => {
      beforeEach(async () => {
        mockEmoji = await initEmojiMock();
        wrapper = createComponent({ currentEmoji: '', currentMessage: '' });
        jest.spyOn(UserApi, 'updateUserStatus').mockResolvedValue();
        return initModal({ mockOnUpdateSuccess: false });
      });

      it('displays a toast success message', async () => {
        findModal().vm.$emit('ok');
        await wrapper.vm.$nextTick();

        expect($toast.show).toHaveBeenCalledWith('Status updated');
      });
    });

    describe('with errors', () => {
      beforeEach(async () => {
        mockEmoji = await initEmojiMock();
        wrapper = createComponent();
        await initModal();

        jest.spyOn(UserApi, 'updateUserStatus').mockRejectedValue();
      });

      it('calls the "onUpdateFail" handler', async () => {
        findModal().vm.$emit('ok');
        await wrapper.vm.$nextTick();

        expect(wrapper.vm.onUpdateFail).toHaveBeenCalled();
      });
    });

    describe('error message', () => {
      beforeEach(async () => {
        mockEmoji = await initEmojiMock();
        wrapper = createComponent({ currentEmoji: '', currentMessage: '' });
        jest.spyOn(UserApi, 'updateUserStatus').mockRejectedValue();
        return initModal({ mockOnUpdateFailure: false });
      });

      it('flashes an error message', async () => {
        findModal().vm.$emit('ok');
        await wrapper.vm.$nextTick();

        expect(createFlash).toHaveBeenCalledWith({
          message: "Sorry, we weren't able to set your status. Please try again later.",
        });
      });
    });
  });
});
