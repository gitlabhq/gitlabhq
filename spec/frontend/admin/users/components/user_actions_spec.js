import { GlDropdownDivider } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import Actions from '~/admin/users/components/actions';
import AdminUserActions from '~/admin/users/components/user_actions.vue';
import { I18N_USER_ACTIONS } from '~/admin/users/constants';
import { generateUserPaths } from '~/admin/users/utils';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';

import { CONFIRMATION_ACTIONS, DELETE_ACTIONS, LDAP, EDIT } from '../constants';
import { users, paths } from '../mock_data';

describe('AdminUserActions component', () => {
  let wrapper;
  const user = users[0];
  const userPaths = generateUserPaths(paths, user.username);

  const findUserActions = (id) => wrapper.findByTestId(`user-actions-${id}`);
  const findEditButton = (id = user.id) => findUserActions(id).find('[data-testid="edit"]');
  const findActionsDropdown = (id = user.id) =>
    findUserActions(id).find('[data-testid="dropdown-toggle"]');
  const findDropdownDivider = () => wrapper.findComponent(GlDropdownDivider);

  const initComponent = ({ actions = [] } = {}) => {
    wrapper = shallowMountExtended(AdminUserActions, {
      propsData: {
        user: {
          ...user,
          actions,
        },
        paths,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('edit button', () => {
    describe('when the user has an edit action attached', () => {
      beforeEach(() => {
        initComponent({ actions: [EDIT] });
      });

      it('renders the edit button linking to the user edit path', () => {
        expect(findEditButton().exists()).toBe(true);
        expect(findEditButton().attributes('href')).toBe(userPaths.edit);
      });
    });

    describe('when there is no edit action attached to the user', () => {
      beforeEach(() => {
        initComponent({ actions: [] });
      });

      it('does not render the edit button linking to the user edit path', () => {
        expect(findEditButton().exists()).toBe(false);
      });
    });
  });

  describe('actions dropdown', () => {
    describe('when there are actions', () => {
      const actions = [EDIT, ...CONFIRMATION_ACTIONS];

      beforeEach(() => {
        initComponent({ actions });
      });

      it('renders the actions dropdown', () => {
        expect(findActionsDropdown().exists()).toBe(true);
      });

      describe('when there are actions that require confirmation', () => {
        beforeEach(() => {
          initComponent({ actions: CONFIRMATION_ACTIONS });
        });

        it.each(CONFIRMATION_ACTIONS)('renders an action component item for "%s"', (action) => {
          const component = wrapper.find(Actions[capitalizeFirstCharacter(action)]);

          expect(component.props('username')).toBe(user.name);
          expect(component.props('path')).toBe(userPaths[action]);
          expect(component.text()).toBe(I18N_USER_ACTIONS[action]);
        });
      });

      describe('when there is a LDAP action', () => {
        beforeEach(() => {
          initComponent({ actions: [LDAP] });
        });

        it('renders the LDAP dropdown item without a link', () => {
          const dropdownAction = wrapper.find(`[data-testid="${LDAP}"]`);
          expect(dropdownAction.exists()).toBe(true);
          expect(dropdownAction.attributes('href')).toBe(undefined);
          expect(dropdownAction.text()).toBe(I18N_USER_ACTIONS[LDAP]);
        });
      });

      describe('when there is a delete action', () => {
        beforeEach(() => {
          initComponent({ actions: [LDAP, ...DELETE_ACTIONS] });
        });

        it('renders a dropdown divider', () => {
          expect(findDropdownDivider().exists()).toBe(true);
        });

        it('only renders delete dropdown items for actions containing the word "delete"', () => {
          const { length } = wrapper.findAll(`[data-testid*="delete-"]`);
          expect(length).toBe(DELETE_ACTIONS.length);
        });

        it.each(DELETE_ACTIONS)('renders a delete action component item for "%s"', (action) => {
          const component = wrapper.find(Actions[capitalizeFirstCharacter(action)]);

          expect(component.props('username')).toBe(user.name);
          expect(component.props('paths')).toEqual(userPaths);
          expect(component.text()).toBe(I18N_USER_ACTIONS[action]);
        });
      });

      describe('when there are no delete actions', () => {
        it('does not render a dropdown divider', () => {
          expect(findDropdownDivider().exists()).toBe(false);
        });

        it('does not render a delete dropdown item', () => {
          const anyDeleteAction = wrapper.find(`[data-testid*="delete-"]`);
          expect(anyDeleteAction.exists()).toBe(false);
        });
      });
    });

    describe('when there are no actions', () => {
      beforeEach(() => {
        initComponent({ actions: [] });
      });

      it('does not render the actions dropdown', () => {
        expect(findActionsDropdown().exists()).toBe(false);
      });
    });
  });
});
