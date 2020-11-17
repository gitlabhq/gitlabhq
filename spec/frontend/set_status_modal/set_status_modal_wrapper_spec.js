import { shallowMount } from '@vue/test-utils';
import { GlModal, GlFormCheckbox } from '@gitlab/ui';
import { initEmojiMock } from 'helpers/emoji';
import Api from '~/api';
import { deprecatedCreateFlash as createFlash } from '~/flash';
import SetStatusModalWrapper, {
  AVAILABILITY_STATUS,
} from '~/set_status_modal/set_status_modal_wrapper.vue';

jest.mock('~/api');
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
    canSetUserAvailability: true,
  };

  const createComponent = (props = {}) => {
    return shallowMount(SetStatusModalWrapper, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      mocks: {
        $toast,
      },
    });
  };

  const findModal = () => wrapper.find(GlModal);
  const findFormField = field => wrapper.find(`[name="user[status][${field}]"]`);
  const findClearStatusButton = () => wrapper.find('.js-clear-user-status-button');
  const findNoEmojiPlaceholder = () => wrapper.find('.js-no-emoji-placeholder');
  const findToggleEmojiButton = () => wrapper.find('.js-toggle-emoji-menu');
  const findAvailabilityCheckbox = () => wrapper.find(GlFormCheckbox);

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

  beforeEach(async () => {
    mockEmoji = await initEmojiMock();
    wrapper = createComponent();
    return initModal();
  });

  afterEach(() => {
    wrapper.destroy();
    mockEmoji.restore();
  });

  describe('with minimum props', () => {
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

  describe('update status', () => {
    describe('succeeds', () => {
      beforeEach(() => {
        jest.spyOn(Api, 'postUserStatus').mockResolvedValue();
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

        findModal().vm.$emit('ok');
        await wrapper.vm.$nextTick();

        const commonParams = { emoji: defaultEmoji, message: defaultMessage };

        expect(Api.postUserStatus).toHaveBeenCalledTimes(2);
        expect(Api.postUserStatus).toHaveBeenNthCalledWith(1, {
          availability: AVAILABILITY_STATUS.NOT_SET,
          ...commonParams,
        });
        expect(Api.postUserStatus).toHaveBeenNthCalledWith(2, {
          availability: AVAILABILITY_STATUS.BUSY,
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
        jest.spyOn(Api, 'postUserStatus').mockResolvedValue();
        return initModal({ mockOnUpdateSuccess: false });
      });

      it('displays a toast success message', async () => {
        findModal().vm.$emit('ok');
        await wrapper.vm.$nextTick();

        expect($toast.show).toHaveBeenCalledWith('Status updated', {
          position: 'top-center',
          type: 'success',
        });
      });
    });

    describe('with errors', () => {
      beforeEach(() => {
        jest.spyOn(Api, 'postUserStatus').mockRejectedValue();
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
        jest.spyOn(Api, 'postUserStatus').mockRejectedValue();
        return initModal({ mockOnUpdateFailure: false });
      });

      it('flashes an error message', async () => {
        findModal().vm.$emit('ok');
        await wrapper.vm.$nextTick();

        expect(createFlash).toHaveBeenCalledWith(
          "Sorry, we weren't able to set your status. Please try again later.",
        );
      });
    });
  });

  describe('with canSetUserAvailability=false', () => {
    beforeEach(async () => {
      mockEmoji = await initEmojiMock();
      wrapper = createComponent({ canSetUserAvailability: false });
      return initModal();
    });

    it('hides the set availability checkbox', () => {
      expect(findAvailabilityCheckbox().exists()).toBe(false);
    });
  });
});
