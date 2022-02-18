import { GlButton, GlFormInput, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import DeleteUserModal from '~/admin/users/components/modals/delete_user_modal.vue';
import UserDeletionObstaclesList from '~/vue_shared/components/user_deletion_obstacles/user_deletion_obstacles_list.vue';
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
  const findUserDeletionObstaclesList = () => wrapper.findComponent(UserDeletionObstaclesList);

  const setUsername = (username) => {
    findUsernameInput().vm.$emit('input', username);
  };

  const username = 'username';
  const badUsername = 'bad_username';
  const userDeletionObstacles = '["schedule1", "policy1"]';

  const createComponent = (props = {}, stubs = {}) => {
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
        userDeletionObstacles,
        ...props,
      },
      stubs: {
        GlModal: ModalStub,
        ...stubs,
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
    beforeEach(async () => {
      createComponent();
      setUsername(badUsername);

      await nextTick();
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
    beforeEach(async () => {
      createComponent();
      setUsername(username);

      await nextTick();
    });

    it('shows correct username', () => {
      expect(getUsername()).toEqual(username);
    });

    it('has enabled buttons', () => {
      expect(findPrimaryButton().attributes('disabled')).toBeFalsy();
      expect(findSecondaryButton().attributes('disabled')).toBeFalsy();
    });

    describe('when primary action is submitted', () => {
      beforeEach(async () => {
        findPrimaryButton().vm.$emit('click');

        await nextTick();
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
      beforeEach(async () => {
        findSecondaryButton().vm.$emit('click');

        await nextTick();
      });

      it('has correct form attributes and calls submit', () => {
        expect(getFormAction()).toBe(TEST_BLOCK_USER_URL);
        expect(getMethodParam()).toBe('put');
        expect(findAuthenticityToken()).toBe(TEST_CSRF);
        expect(formSubmitSpy).toHaveBeenCalled();
      });
    });
  });

  describe("when user's name has leading and trailing whitespace", () => {
    beforeEach(() => {
      createComponent(
        {
          username: ' John Smith ',
        },
        { GlSprintf },
      );
    });

    it("displays user's name without whitespace", () => {
      expect(wrapper.element).toMatchSnapshot();
    });

    it("shows enabled buttons when user's name is entered without whitespace", async () => {
      setUsername('John Smith');

      await nextTick();

      expect(findPrimaryButton().attributes('disabled')).toBeUndefined();
      expect(findSecondaryButton().attributes('disabled')).toBeUndefined();
    });
  });

  describe('Related user-deletion-obstacles list', () => {
    it('does NOT render the list when user has no related obstacles', () => {
      createComponent({ userDeletionObstacles: '[]' });
      expect(findUserDeletionObstaclesList().exists()).toBe(false);
    });

    it('renders the list when user has related obstalces', () => {
      createComponent();

      const obstacles = findUserDeletionObstaclesList();
      expect(obstacles.exists()).toBe(true);
      expect(obstacles.props('obstacles')).toEqual(JSON.parse(userDeletionObstacles));
    });
  });
});
