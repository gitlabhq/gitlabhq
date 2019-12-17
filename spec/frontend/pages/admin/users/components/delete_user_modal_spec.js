import { shallowMount } from '@vue/test-utils';
import { GlButton, GlFormInput } from '@gitlab/ui';
import DeleteUserModal from '~/pages/admin/users/components/delete_user_modal.vue';
import ModalStub from './stubs/modal_stub';

const TEST_DELETE_USER_URL = 'delete-url';
const TEST_BLOCK_USER_URL = 'block-url';
const TEST_CSRF = 'csrf';

describe('User Operation confirmation modal', () => {
  let wrapper;
  let formSubmitSpy;

  const findButton = variant =>
    wrapper
      .findAll(GlButton)
      .filter(w => w.attributes('variant') === variant)
      .at(0);
  const findForm = () => wrapper.find('form');
  const findUsernameInput = () => wrapper.find(GlFormInput);
  const findPrimaryButton = () => findButton('danger');
  const findSecondaryButton = () => findButton('warning');
  const findAuthenticityToken = () => new FormData(findForm().element).get('authenticity_token');
  const getUsername = () => findUsernameInput().attributes('value');
  const getMethodParam = () => new FormData(findForm().element).get('_method');
  const getFormAction = () => findForm().attributes('action');

  const setUsername = username => {
    findUsernameInput().vm.$emit('input', username);
  };

  const username = 'username';
  const badUsername = 'bad_username';

  const createComponent = (props = {}) => {
    wrapper = shallowMount(DeleteUserModal, {
      propsData: {
        username,
        title: 'title',
        content: 'content',
        action: 'action',
        secondaryAction: 'secondaryAction',
        deleteUserUrl: TEST_DELETE_USER_URL,
        blockUserUrl: TEST_BLOCK_USER_URL,
        csrfToken: TEST_CSRF,
        ...props,
      },
      stubs: {
        GlModal: ModalStub,
      },
      sync: false,
    });
  };

  beforeEach(() => {
    formSubmitSpy = jest.spyOn(HTMLFormElement.prototype, 'submit').mockImplementation();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('renders modal with form included', () => {
    createComponent();
    expect(wrapper.element).toMatchSnapshot();
  });

  describe('on created', () => {
    beforeEach(() => {
      createComponent();
    });

    it('has disabled buttons', () => {
      expect(findPrimaryButton().attributes('disabled')).toBeTruthy();
      expect(findSecondaryButton().attributes('disabled')).toBeTruthy();
    });
  });

  describe('with incorrect username', () => {
    beforeEach(() => {
      createComponent();
      setUsername(badUsername);

      return wrapper.vm.$nextTick();
    });

    it('shows incorrect username', () => {
      expect(getUsername()).toEqual(badUsername);
    });

    it('has disabled buttons', () => {
      expect(findPrimaryButton().attributes('disabled')).toBeTruthy();
      expect(findSecondaryButton().attributes('disabled')).toBeTruthy();
    });
  });

  describe('with correct username', () => {
    beforeEach(() => {
      createComponent();
      setUsername(username);

      return wrapper.vm.$nextTick();
    });

    it('shows correct username', () => {
      expect(getUsername()).toEqual(username);
    });

    it('has enabled buttons', () => {
      expect(findPrimaryButton().attributes('disabled')).toBeFalsy();
      expect(findSecondaryButton().attributes('disabled')).toBeFalsy();
    });

    describe('when primary action is submitted', () => {
      beforeEach(() => {
        findPrimaryButton().vm.$emit('click');

        return wrapper.vm.$nextTick();
      });

      it('clears the input', () => {
        expect(getUsername()).toEqual('');
      });

      it('has correct form attributes and calls submit', () => {
        expect(getFormAction()).toBe(TEST_DELETE_USER_URL);
        expect(getMethodParam()).toBe('delete');
        expect(findAuthenticityToken()).toBe(TEST_CSRF);
        expect(formSubmitSpy).toHaveBeenCalled();
      });
    });

    describe('when secondary action is submitted', () => {
      beforeEach(() => {
        findSecondaryButton().vm.$emit('click');

        return wrapper.vm.$nextTick();
      });

      it('has correct form attributes and calls submit', () => {
        expect(getFormAction()).toBe(TEST_BLOCK_USER_URL);
        expect(getMethodParam()).toBe('put');
        expect(findAuthenticityToken()).toBe(TEST_CSRF);
        expect(formSubmitSpy).toHaveBeenCalled();
      });
    });
  });
});
