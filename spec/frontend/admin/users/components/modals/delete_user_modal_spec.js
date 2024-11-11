import { GlButton, GlFormInput, GlSprintf } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import eventHub, {
  EVENT_OPEN_DELETE_USER_MODAL,
} from '~/admin/users/components/modals/delete_user_modal_event_hub';
import DeleteUserModal from '~/admin/users/components/modals/delete_user_modal.vue';
import UserDeletionObstaclesList from '~/vue_shared/components/user_deletion_obstacles/user_deletion_obstacles_list.vue';
import AssociationsList from '~/admin/users/components/associations/associations_list.vue';
import SoloOwnedOrganizationsMessage from '~/admin/users/components/solo_owned_organizations_message.vue';
import { oneSoloOwnedOrganization } from '../../mock_data';
import ModalStub from './stubs/modal_stub';

const TEST_DELETE_USER_URL = 'delete-url';
const TEST_BLOCK_USER_URL = 'block-url';
const TEST_CSRF = 'csrf';

describe('Delete user modal', () => {
  let wrapper;
  let formSubmitSpy;

  const findButton = (variant, category) =>
    wrapper
      .findAllComponents(GlButton)
      .wrappers.find(
        (w) => w.attributes('variant') === variant && w.attributes('category') === category,
      );
  const findForm = () => wrapper.find('form');
  const findUsernameInput = () => wrapper.findComponent(GlFormInput);
  const findPrimaryButton = () => findButton('danger', 'primary');
  const findSecondaryButton = () => findButton('danger', 'secondary');
  const findAuthenticityToken = () => new FormData(findForm().element).get('authenticity_token');
  const getUsername = () => findUsernameInput().attributes('value');
  const getMethodParam = () => new FormData(findForm().element).get('_method');
  const getFormAction = () => findForm().attributes('action');
  const findUserDeletionObstaclesList = () => wrapper.findComponent(UserDeletionObstaclesList);
  const findMessageUsername = () => wrapper.findByTestId('message-username');
  const findConfirmUsername = () => wrapper.findByTestId('confirm-username');
  const findAssociationsList = () => wrapper.findComponent(AssociationsList);

  const emitOpenModalEvent = (modalData) => {
    return eventHub.$emit(EVENT_OPEN_DELETE_USER_MODAL, modalData);
  };
  const setUsername = (username) => {
    return findUsernameInput().vm.$emit('input', username);
  };

  const username = 'username';
  const badUsername = 'bad_username';
  const userDeletionObstacles = ['schedule1', 'policy1'];

  const mockModalData = {
    username,
    blockPath: TEST_BLOCK_USER_URL,
    deletePath: TEST_DELETE_USER_URL,
    userDeletionObstacles,
    i18n: {
      title: 'Modal for %{username}',
      primaryButtonLabel: 'Delete user',
      messageBody: 'Delete %{username} or rather %{strongStart}block user%{strongEnd}?',
    },
  };

  const createComponent = (stubs = {}) => {
    wrapper = shallowMountExtended(DeleteUserModal, {
      propsData: {
        csrfToken: TEST_CSRF,
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

  it('renders modal with form included', () => {
    createComponent();
    expect(findForm().element).toMatchSnapshot();
  });

  describe('on created', () => {
    beforeEach(() => {
      createComponent();
    });

    it('has disabled buttons', () => {
      expect(findPrimaryButton().attributes('disabled')).toBeDefined();
      expect(findSecondaryButton().attributes('disabled')).toBeDefined();
    });
  });

  describe('with incorrect username', () => {
    beforeEach(() => {
      createComponent();
      emitOpenModalEvent(mockModalData);

      return setUsername(badUsername);
    });

    it('shows incorrect username', () => {
      expect(getUsername()).toEqual(badUsername);
    });

    it('has disabled buttons', () => {
      expect(findPrimaryButton().attributes('disabled')).toBeDefined();
      expect(findSecondaryButton().attributes('disabled')).toBeDefined();
    });
  });

  describe('with correct username', () => {
    beforeEach(() => {
      createComponent();
      emitOpenModalEvent(mockModalData);

      return setUsername(username);
    });

    it('shows correct username', () => {
      expect(getUsername()).toEqual(username);
    });

    it('has enabled buttons', () => {
      expect(findPrimaryButton().attributes('disabled')).toBeUndefined();
      expect(findSecondaryButton().attributes('disabled')).toBeUndefined();
    });

    describe('when primary action is clicked', () => {
      beforeEach(() => {
        return findPrimaryButton().vm.$emit('click');
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

    describe('when secondary action is clicked', () => {
      beforeEach(() => {
        return findSecondaryButton().vm.$emit('click');
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
      createComponent({ GlSprintf });
      return emitOpenModalEvent({ ...mockModalData, username: ' John Smith ' });
    });

    it("displays user's name without whitespace", () => {
      expect(findMessageUsername().text()).toBe('John Smith');
      expect(findConfirmUsername().text()).toBe('John Smith');
    });

    it('passes user name without whitespace to the obstacles', () => {
      expect(findUserDeletionObstaclesList().props()).toMatchObject({
        userName: 'John Smith',
      });
    });

    it("shows enabled buttons when user's name is entered without whitespace", async () => {
      await setUsername('John Smith');

      expect(findPrimaryButton().attributes('disabled')).toBeUndefined();
      expect(findSecondaryButton().attributes('disabled')).toBeUndefined();
    });
  });

  describe('Related user-deletion-obstacles list', () => {
    it('does NOT render the list when user has no related obstacles', async () => {
      createComponent();
      await emitOpenModalEvent({ ...mockModalData, userDeletionObstacles: [] });

      expect(findUserDeletionObstaclesList().exists()).toBe(false);
    });

    it('renders the list when user has related obstalces', async () => {
      createComponent();
      await emitOpenModalEvent(mockModalData);

      const obstacles = findUserDeletionObstaclesList();
      expect(obstacles.exists()).toBe(true);
      expect(obstacles.props('obstacles')).toEqual(userDeletionObstacles);
    });
  });

  it('renders `AssociationsList` component and passes `associationsCount` prop', async () => {
    const associationsCount = {
      groups_count: 5,
      projects_count: 0,
      issues_count: 5,
      merge_requests_count: 5,
    };

    createComponent();
    emitOpenModalEvent({
      ...mockModalData,
      associationsCount,
    });
    await nextTick();

    expect(findAssociationsList().props('associationsCount')).toEqual(associationsCount);
  });

  describe('when user has solo owned organizations', () => {
    beforeEach(() => {
      createComponent();
      emitOpenModalEvent({
        ...mockModalData,
        organizations: oneSoloOwnedOrganization,
      });
    });

    it('shows only SoloOwnedOrganizationsMessage component', () => {
      expect(wrapper.findComponent(SoloOwnedOrganizationsMessage).props()).toMatchObject({
        organizations: oneSoloOwnedOrganization,
      });
    });

    it('only shows cancel button', () => {
      expect(wrapper.findByTestId('cancel-button').exists()).toBe(true);
      expect(findPrimaryButton()).toBeUndefined();
      expect(findSecondaryButton()).toBeUndefined();
    });

    it('does not render `AssociationsList` component', () => {
      expect(findAssociationsList().exists()).toBe(false);
    });

    it('does not render `UserDeletionObstaclesList` component', () => {
      expect(findUserDeletionObstaclesList().exists()).toBe(false);
    });

    it("does not render user's name", () => {
      expect(findMessageUsername().exists()).toBe(false);
    });
  });
});
