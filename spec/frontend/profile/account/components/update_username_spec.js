import { GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { TEST_HOST } from 'helpers/test_constants';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';

import UpdateUsername from '~/profile/account/components/update_username.vue';

jest.mock('~/flash');

describe('UpdateUsername component', () => {
  const rootUrl = TEST_HOST;
  const actionUrl = `${TEST_HOST}/update/username`;
  const defaultProps = {
    actionUrl,
    rootUrl,
    initialUsername: 'hasnoname',
  };
  let wrapper;
  let axiosMock;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(UpdateUsername, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: {
        GlModal,
      },
    });
  };

  beforeEach(() => {
    axiosMock = new MockAdapter(axios);
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    axiosMock.restore();
  });

  const findElements = () => {
    const modal = wrapper.find(GlModal);

    return {
      modal,
      input: wrapper.find(`#${wrapper.vm.$options.inputId}`),
      openModalBtn: wrapper.find('[data-testid="username-change-confirmation-modal"]'),
      modalBody: modal.find('.modal-body'),
      modalHeader: modal.find('.modal-title'),
      confirmModalBtn: wrapper.find('.btn-warning'),
    };
  };

  it('has a disabled button if the username was not changed', async () => {
    const { openModalBtn } = findElements();

    await wrapper.vm.$nextTick();

    expect(openModalBtn.props('disabled')).toBe(true);
  });

  it('has an enabled button which if the username was changed', async () => {
    const { input, openModalBtn } = findElements();

    input.element.value = 'newUsername';
    input.trigger('input');

    await wrapper.vm.$nextTick();

    expect(openModalBtn.props('disabled')).toBe(false);
  });

  describe('changing username', () => {
    const newUsername = 'new_username';

    beforeEach(async () => {
      createComponent();
      wrapper.setData({ newUsername });

      await wrapper.vm.$nextTick();
    });

    it('confirmation modal contains proper header and body', async () => {
      const { modal } = findElements();

      expect(modal.props('title')).toBe('Change username?');
      expect(modal.text()).toContain(
        `You are going to change the username ${defaultProps.initialUsername} to ${newUsername}`,
      );
    });

    it('executes API call on confirmation button click', async () => {
      axiosMock.onPut(actionUrl).replyOnce(() => [200, { message: 'Username changed' }]);
      jest.spyOn(axios, 'put');

      await wrapper.vm.onConfirm();
      await wrapper.vm.$nextTick();

      expect(axios.put).toHaveBeenCalledWith(actionUrl, { user: { username: newUsername } });
    });

    it('sets the username after a successful update', async () => {
      const { input, openModalBtn } = findElements();

      axiosMock.onPut(actionUrl).replyOnce(() => {
        expect(input.attributes('disabled')).toBe('disabled');
        expect(openModalBtn.props('disabled')).toBe(false);
        expect(openModalBtn.props('loading')).toBe(true);

        return [200, { message: 'Username changed' }];
      });

      await wrapper.vm.onConfirm();
      await wrapper.vm.$nextTick();

      expect(input.attributes('disabled')).toBe(undefined);
      expect(openModalBtn.props('disabled')).toBe(true);
      expect(openModalBtn.props('loading')).toBe(false);
    });

    it('does not set the username after a erroneous update', async () => {
      const { input, openModalBtn } = findElements();

      axiosMock.onPut(actionUrl).replyOnce(() => {
        expect(input.attributes('disabled')).toBe('disabled');
        expect(openModalBtn.props('disabled')).toBe(false);
        expect(openModalBtn.props('loading')).toBe(true);

        return [400, { message: 'Invalid username' }];
      });

      await expect(wrapper.vm.onConfirm()).rejects.toThrow();
      expect(input.attributes('disabled')).toBe(undefined);
      expect(openModalBtn.props('disabled')).toBe(false);
      expect(openModalBtn.props('loading')).toBe(false);
    });

    it('shows an error message if the error response has a `message` property', async () => {
      axiosMock.onPut(actionUrl).replyOnce(() => {
        return [400, { message: 'Invalid username' }];
      });

      await expect(wrapper.vm.onConfirm()).rejects.toThrow();

      expect(createFlash).toBeCalledWith({
        message: 'Invalid username',
      });
    });

    it("shows a fallback error message if the error response doesn't have a `message` property", async () => {
      axiosMock.onPut(actionUrl).replyOnce(() => {
        return [400];
      });

      await expect(wrapper.vm.onConfirm()).rejects.toThrow();

      expect(createFlash).toBeCalledWith({
        message: 'An error occurred while updating your username, please try again.',
      });
    });
  });
});
