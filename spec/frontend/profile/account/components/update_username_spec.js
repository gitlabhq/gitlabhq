import { GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import { TEST_HOST } from 'helpers/test_constants';
import { createAlert } from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
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
    const modal = wrapper.findComponent(GlModal);

    return {
      modal,
      input: wrapper.find(`#${wrapper.vm.$options.inputId}`),
      openModalBtn: wrapper.find('[data-testid="username-change-confirmation-modal"]'),
      modalBody: modal.find('.modal-body'),
      modalHeader: modal.find('.modal-title'),
      confirmModalBtn: wrapper.find('.btn-confirm'),
    };
  };

  it('has a disabled button if the username was not changed', async () => {
    const { openModalBtn } = findElements();

    await nextTick();

    expect(openModalBtn.props('disabled')).toBe(true);
  });

  it('has an enabled button which if the username was changed', async () => {
    const { input, openModalBtn } = findElements();

    input.element.value = 'newUsername';
    input.trigger('input');

    await nextTick();

    expect(openModalBtn.props('disabled')).toBe(false);
  });

  describe('changing username', () => {
    const newUsername = 'new_username';

    beforeEach(async () => {
      createComponent();
      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({ newUsername });

      await nextTick();
    });

    it('confirmation modal contains proper header and body', async () => {
      const { modal } = findElements();

      expect(modal.props('title')).toBe('Change username?');
      expect(modal.text()).toContain(
        `You are going to change the username ${defaultProps.initialUsername} to ${newUsername}`,
      );
    });

    it('executes API call on confirmation button click', async () => {
      axiosMock.onPut(actionUrl).replyOnce(() => [HTTP_STATUS_OK, { message: 'Username changed' }]);
      jest.spyOn(axios, 'put');

      await wrapper.vm.onConfirm();
      await nextTick();

      expect(axios.put).toHaveBeenCalledWith(actionUrl, { user: { username: newUsername } });
    });

    it('sets the username after a successful update', async () => {
      const { input, openModalBtn } = findElements();

      axiosMock.onPut(actionUrl).replyOnce(() => {
        expect(input.attributes('disabled')).toBe('disabled');
        expect(openModalBtn.props('disabled')).toBe(false);
        expect(openModalBtn.props('loading')).toBe(true);

        return [HTTP_STATUS_OK, { message: 'Username changed' }];
      });

      await wrapper.vm.onConfirm();
      await nextTick();

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

      expect(createAlert).toHaveBeenCalledWith({
        message: 'Invalid username',
      });
    });

    it("shows a fallback error message if the error response doesn't have a `message` property", async () => {
      axiosMock.onPut(actionUrl).replyOnce(() => {
        return [400];
      });

      await expect(wrapper.vm.onConfirm()).rejects.toThrow();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'An error occurred while updating your username, please try again.',
      });
    });
  });
});
