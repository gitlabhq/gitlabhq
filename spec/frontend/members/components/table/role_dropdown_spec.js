import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { GlBreakpointInstance as bp } from '@gitlab/ui/dist/utils';
import * as Sentry from '@sentry/browser';
import { within } from '@testing-library/dom';
import { mount, createWrapper } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import waitForPromises from 'helpers/wait_for_promises';
import RoleDropdown from '~/members/components/table/role_dropdown.vue';
import { MEMBER_TYPES } from '~/members/constants';
import { guestOverageConfirmAction } from 'ee_else_ce/members/guest_overage_confirm_action';
import { member } from '../../mock_data';

Vue.use(Vuex);
jest.mock('ee_else_ce/members/guest_overage_confirm_action');
jest.mock('@sentry/browser');

describe('RoleDropdown', () => {
  let wrapper;
  let actions;
  const $toast = {
    show: jest.fn(),
  };

  const createStore = ({ updateMemberRoleReturn = Promise.resolve() } = {}) => {
    actions = {
      updateMemberRole: jest.fn(() => updateMemberRoleReturn),
    };

    return new Vuex.Store({
      modules: {
        [MEMBER_TYPES.user]: { namespaced: true, actions },
      },
    });
  };

  const createComponent = (propsData = {}, store = createStore()) => {
    wrapper = mount(RoleDropdown, {
      provide: {
        namespace: MEMBER_TYPES.user,
        group: {
          name: 'groupname',
          path: '/grouppath/',
        },
      },
      propsData: {
        member,
        permissions: {},
        ...propsData,
      },
      store,
      mocks: {
        $toast,
      },
    });
  };

  const getDropdownMenu = () => within(wrapper.element).getByRole('menu');
  const getByTextInDropdownMenu = (text, options = {}) =>
    createWrapper(within(getDropdownMenu()).getByText(text, options));
  const getDropdownItemByText = (text) =>
    createWrapper(
      within(getDropdownMenu())
        .getByText(text, { selector: '[role="menuitem"] p' })
        .closest('[role="menuitem"]'),
    );
  const getCheckedDropdownItem = () =>
    wrapper
      .findAllComponents(GlDropdownItem)
      .wrappers.find((dropdownItemWrapper) => dropdownItemWrapper.props('isChecked'));

  const findDropdownToggle = () => wrapper.find('button[aria-haspopup="menu"]');
  const findDropdown = () => wrapper.findComponent(GlDropdown);

  beforeEach(() => {
    gon.features = { showOverageOnRolePromotion: true };
  });

  describe('when dropdown is open', () => {
    beforeEach(async () => {
      guestOverageConfirmAction.mockReturnValue(true);
      createComponent();

      await findDropdownToggle().trigger('click');
    });

    it('renders all valid roles', () => {
      Object.keys(member.validRoles).forEach((role) => {
        expect(getDropdownItemByText(role).exists()).toBe(true);
      });
    });

    it('renders dropdown header', () => {
      expect(getByTextInDropdownMenu('Change role').exists()).toBe(true);
    });

    it('sets dropdown toggle and checks selected role', () => {
      expect(findDropdownToggle().text()).toBe('Owner');
      expect(getCheckedDropdownItem().text()).toBe('Owner');
    });

    describe('when dropdown item is selected', () => {
      it('does nothing if the item selected was already selected', async () => {
        await getDropdownItemByText('Owner').trigger('click');

        expect(actions.updateMemberRole).not.toHaveBeenCalled();
      });

      it('calls `updateMemberRole` Vuex action', async () => {
        await getDropdownItemByText('Developer').trigger('click');

        expect(actions.updateMemberRole).toHaveBeenCalledWith(expect.any(Object), {
          memberId: member.id,
          accessLevel: { integerValue: 30, stringValue: 'Developer' },
        });
      });

      describe('when updateMemberRole is successful', () => {
        it('displays toast', async () => {
          await getDropdownItemByText('Developer').trigger('click');

          await nextTick();

          expect($toast.show).toHaveBeenCalledWith('Role updated successfully.');
        });

        it('puts dropdown in loading state while waiting for `updateMemberRole` to resolve', async () => {
          await getDropdownItemByText('Developer').trigger('click');

          expect(findDropdown().props('loading')).toBe(true);
        });

        it('enables dropdown after `updateMemberRole` resolves', async () => {
          await getDropdownItemByText('Developer').trigger('click');

          await waitForPromises();

          expect(findDropdown().props('disabled')).toBe(false);
        });

        it('does not log error to Sentry', async () => {
          await getDropdownItemByText('Developer').trigger('click');

          await waitForPromises();

          expect(Sentry.captureException).not.toHaveBeenCalled();
        });
      });

      describe('when updateMemberRole is not successful', () => {
        const reason = 'Rejected ☹️';

        beforeEach(() => {
          createComponent({}, createStore({ updateMemberRoleReturn: Promise.reject(reason) }));
        });

        it('does not display toast', async () => {
          await getDropdownItemByText('Developer').trigger('click');

          await nextTick();

          expect($toast.show).not.toHaveBeenCalled();
        });

        it('puts dropdown in loading state while waiting for `updateMemberRole` to resolve', async () => {
          await getDropdownItemByText('Developer').trigger('click');

          expect(findDropdown().props('loading')).toBe(true);
        });

        it('enables dropdown after `updateMemberRole` resolves', async () => {
          await getDropdownItemByText('Developer').trigger('click');

          await waitForPromises();

          expect(findDropdown().props('disabled')).toBe(false);
        });

        it('logs error to Sentry', async () => {
          await getDropdownItemByText('Developer').trigger('click');

          await waitForPromises();

          expect(Sentry.captureException).toHaveBeenCalledWith(reason);
        });
      });
    });
  });

  it("sets initial dropdown toggle value to member's role", () => {
    createComponent();

    expect(findDropdownToggle().text()).toBe('Owner');
  });

  it('sets the dropdown alignment to right on mobile', async () => {
    jest.spyOn(bp, 'isDesktop').mockReturnValue(false);
    createComponent();

    await nextTick();

    expect(findDropdown().props('right')).toBe(true);
  });

  it('sets the dropdown alignment to left on desktop', async () => {
    jest.spyOn(bp, 'isDesktop').mockReturnValue(true);
    createComponent();

    await nextTick();

    expect(findDropdown().props('right')).toBe(false);
  });

  describe('guestOverageConfirmAction', () => {
    const mockConfirmAction = ({ confirmed }) => {
      guestOverageConfirmAction.mockResolvedValueOnce(confirmed);
    };

    beforeEach(() => {
      createComponent();

      findDropdownToggle().trigger('click');
    });

    afterEach(() => {
      guestOverageConfirmAction.mockReset();
    });

    describe('when guestOverageConfirmAction returns true', () => {
      beforeEach(() => {
        mockConfirmAction({ confirmed: true });

        getDropdownItemByText('Reporter').trigger('click');
      });

      it('calls updateMemberRole', () => {
        expect(actions.updateMemberRole).toHaveBeenCalled();
      });
    });

    describe('when guestOverageConfirmAction returns false', () => {
      beforeEach(() => {
        mockConfirmAction({ confirmed: false });

        getDropdownItemByText('Reporter').trigger('click');
      });

      it('does not call updateMemberRole', () => {
        expect(actions.updateMemberRole).not.toHaveBeenCalled();
      });
    });
  });
});
