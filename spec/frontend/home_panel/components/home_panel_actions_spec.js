import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import HomePanelActions from '~/pages/projects/home_panel/components/home_panel_actions.vue';
import ForksButton from '~/forks/components/forks_button.vue';
import MoreActionsDropdown from '~/groups_projects/components/more_actions_dropdown.vue';
import NotificationsDropdown from '~/notifications/components/notifications_dropdown.vue';
import StarCount from '~/stars/components/star_count.vue';

describe('HomePanelActions', () => {
  let wrapper;

  const createComponent = ({ isLoggedIn = false, provide = {} } = {}) => {
    if (isLoggedIn) {
      window.gon.current_user_id = 1;
    }

    wrapper = shallowMountExtended(HomePanelActions, {
      provide: {
        ...provide,
      },
    });
  };

  const findAdminButton = () => wrapper.find('[data-testid="admin-button"]');
  const findForksButton = () => wrapper.findComponent(ForksButton);
  const findMoreActionsDropdown = () => wrapper.findComponent(MoreActionsDropdown);
  const findNotificationsDropdown = () => wrapper.findComponent(NotificationsDropdown);
  const findStarCount = () => wrapper.findComponent(StarCount);

  describe.each`
    isLoggedIn | canReadProject | isProjectEmpty | adminPath               | isForkButtonVisible | isMoreActionsDropdownVisible | isNotificationDropdownVisible | isStarCountVisible | isAdminButtonVisible
    ${true}    | ${true}        | ${true}        | ${undefined}            | ${false}            | ${true}                      | ${true}                       | ${true}            | ${false}
    ${true}    | ${true}        | ${true}        | ${null}                 | ${false}            | ${true}                      | ${true}                       | ${true}            | ${false}
    ${true}    | ${true}        | ${true}        | ${''}                   | ${false}            | ${true}                      | ${true}                       | ${true}            | ${false}
    ${true}    | ${true}        | ${false}       | ${''}                   | ${true}             | ${true}                      | ${true}                       | ${true}            | ${false}
    ${true}    | ${false}       | ${true}        | ${''}                   | ${false}            | ${true}                      | ${false}                      | ${true}            | ${false}
    ${true}    | ${false}       | ${false}       | ${''}                   | ${false}            | ${true}                      | ${false}                      | ${true}            | ${false}
    ${true}    | ${true}        | ${true}        | ${'project/admin/path'} | ${false}            | ${true}                      | ${true}                       | ${true}            | ${true}
    ${true}    | ${true}        | ${false}       | ${'project/admin/path'} | ${true}             | ${true}                      | ${true}                       | ${true}            | ${true}
    ${true}    | ${false}       | ${true}        | ${'project/admin/path'} | ${false}            | ${true}                      | ${false}                      | ${true}            | ${true}
    ${true}    | ${false}       | ${false}       | ${'project/admin/path'} | ${false}            | ${true}                      | ${false}                      | ${true}            | ${true}
    ${false}   | ${true}        | ${true}        | ${''}                   | ${false}            | ${true}                      | ${false}                      | ${true}            | ${false}
    ${false}   | ${true}        | ${false}       | ${''}                   | ${false}            | ${true}                      | ${false}                      | ${true}            | ${false}
    ${false}   | ${false}       | ${true}        | ${''}                   | ${false}            | ${true}                      | ${false}                      | ${true}            | ${false}
    ${false}   | ${false}       | ${false}       | ${''}                   | ${false}            | ${true}                      | ${false}                      | ${true}            | ${false}
    ${false}   | ${true}        | ${true}        | ${'project/admin/path'} | ${false}            | ${true}                      | ${false}                      | ${true}            | ${true}
    ${false}   | ${true}        | ${false}       | ${'project/admin/path'} | ${false}            | ${true}                      | ${false}                      | ${true}            | ${true}
    ${false}   | ${false}       | ${true}        | ${'project/admin/path'} | ${false}            | ${true}                      | ${false}                      | ${true}            | ${true}
    ${false}   | ${false}       | ${false}       | ${'project/admin/path'} | ${false}            | ${true}                      | ${false}                      | ${true}            | ${true}
  `(
    'renders components',
    ({
      isLoggedIn,
      canReadProject,
      isProjectEmpty,
      adminPath,
      isForkButtonVisible,
      isMoreActionsDropdownVisible,
      isNotificationDropdownVisible,
      isStarCountVisible,
      isAdminButtonVisible,
    }) => {
      it('as expected', () => {
        createComponent({
          isLoggedIn,
          provide: {
            adminPath,
            canReadProject,
            isProjectEmpty,
          },
        });

        expect(findForksButton().exists()).toBe(isForkButtonVisible);
        expect(findMoreActionsDropdown().exists()).toBe(isMoreActionsDropdownVisible);
        expect(findNotificationsDropdown().exists()).toBe(isNotificationDropdownVisible);
        expect(findStarCount().exists()).toBe(isStarCountVisible);
        expect(findAdminButton().exists()).toBe(isAdminButtonVisible);
      });
    },
  );
});
