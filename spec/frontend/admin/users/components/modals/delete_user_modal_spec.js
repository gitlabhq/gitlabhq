import { GlButton, GlFormInput } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import DeleteUserModal from '~/admin/users/components/modals/delete_user_modal.vue';
import OncallSchedulesList from '~/vue_shared/components/oncall_schedules_list.vue';
import ModalStub from './stubs/modal_stub';

const TEST_DELETE_USER_URL = 'delete-url';
const TEST_BLOCK_USER_URL = 'block-url';
const TEST_CSRF = 'csrf';

describe('User Operation confirmation modal', () => {
  let wrapper;
  let formSubmitSpy;

  const findButton = (variant, category) =>
    wrapper
      .findAll(GlButton)
      .filter((w) => w.attributes('variant') === variant && w.attributes('category') === category)
      .at(0);
  const findForm = () => wrapper.find('form');
  const findUsernameInput = () => wrapper.findComponent(GlFormInput);
  const findPrimaryButton = () => findButton('danger', 'primary');
  const findSecondaryButton = () => findButton('danger', 'secondary');
  const findAuthenticityToken = () => new FormData(findForm().element).get('authenticity_token');
  const getUsername = () => findUsernameInput().attributes('value');
  const getMethodParam = () => new FormData(findForm().element).get('_method');
  const getFormAction = () => findForm().attributes('action');
  const findOnCallSchedulesList = () => wrapper.findComponent(OncallSchedulesList);

  const setUsername = (username) => {
    findUsernameInput().vm.$emit('input', username);
  };

  const username = 'username';
  const badUsername = 'bad_username';
  const oncallSchedules = '["schedule1", "schedule2"]';

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
        oncallSchedules,
        ...props,
      },
      stubs: {
        GlModal: ModalStub,
      },
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

  describe('Related oncall-schedules list', () => {
    it('does NOT render the list when user has no related schedules', () => {
      createComponent({ oncallSchedules: '[]' });
      expect(findOnCallSchedulesList().exists()).toBe(false);
    });

    it('renders the list when user has related schedules', () => {
      createComponent();

      const schedules = findOnCallSchedulesList();
      expect(schedules.exists()).toBe(true);
      expect(schedules.props('schedules')).toEqual(JSON.parse(oncallSchedules));
    });
  });
});
