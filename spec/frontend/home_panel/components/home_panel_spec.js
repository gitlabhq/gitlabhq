import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import HomePanel from '~/pages/projects/home_panel/components/home_panel.vue';
import ForksButton from '~/forks/components/forks_button.vue';
import MoreActionsDropdown from '~/groups_projects/components/more_actions_dropdown.vue';
import NotificationsDropdown from '~/notifications/components/notifications_dropdown.vue';
import StarCount from '~/stars/components/star_count.vue';

describe('HomePanel', () => {
  let wrapper;

  const createComponent = ({ isLoggedIn = false, provide = {} } = {}) => {
    if (isLoggedIn) {
      window.gon.current_user_id = 1;
    }

    wrapper = shallowMountExtended(HomePanel, {
      provide: {
        ...provide,
      },
    });
  };

  const findForksButton = () => wrapper.findComponent(ForksButton);
  const findMoreActionsDropdown = () => wrapper.findComponent(MoreActionsDropdown);
  const findNotificationsDropdown = () => wrapper.findComponent(NotificationsDropdown);
  const findStarCount = () => wrapper.findComponent(StarCount);

  describe.each`
    isLoggedIn | canReadProject | isProjectEmpty | isForkButtonVisible | isMoreActionsDropdownVisible | isNotificationDropdownVisible | isStarCountVisible
    ${true}    | ${true}        | ${true}        | ${false}            | ${true}                      | ${true}                       | ${true}
    ${true}    | ${true}        | ${false}       | ${true}             | ${true}                      | ${true}                       | ${true}
    ${true}    | ${false}       | ${true}        | ${false}            | ${true}                      | ${false}                      | ${true}
    ${true}    | ${false}       | ${false}       | ${false}            | ${true}                      | ${false}                      | ${true}
    ${false}   | ${true}        | ${true}        | ${false}            | ${true}                      | ${false}                      | ${true}
    ${false}   | ${true}        | ${false}       | ${false}            | ${true}                      | ${false}                      | ${true}
    ${false}   | ${false}       | ${true}        | ${false}            | ${true}                      | ${false}                      | ${true}
    ${false}   | ${false}       | ${false}       | ${false}            | ${true}                      | ${false}                      | ${true}
  `(
    'renders components',
    ({
      isLoggedIn,
      canReadProject,
      isProjectEmpty,
      isForkButtonVisible,
      isMoreActionsDropdownVisible,
      isNotificationDropdownVisible,
      isStarCountVisible,
    }) => {
      it('as expected', () => {
        createComponent({
          isLoggedIn,
          provide: {
            canReadProject,
            isProjectEmpty,
          },
        });

        expect(findForksButton().exists()).toBe(isForkButtonVisible);
        expect(findMoreActionsDropdown().exists()).toBe(isMoreActionsDropdownVisible);
        expect(findNotificationsDropdown().exists()).toBe(isNotificationDropdownVisible);
        expect(findStarCount().exists()).toBe(isStarCountVisible);
      });
    },
  );
});
