import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { GlBreakpointInstance as bp } from '@gitlab/ui/dist/utils';
import { within } from '@testing-library/dom';
import { mount, createWrapper, createLocalVue } from '@vue/test-utils';
import { nextTick } from 'vue';
import Vuex from 'vuex';
import waitForPromises from 'helpers/wait_for_promises';
import { BV_DROPDOWN_SHOW } from '~/lib/utils/constants';
import RoleDropdown from '~/members/components/table/role_dropdown.vue';
import { MEMBER_TYPES } from '~/members/constants';
import { member } from '../../mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('RoleDropdown', () => {
  let wrapper;
  let actions;
  const $toast = {
    show: jest.fn(),
  };

  const createStore = () => {
    actions = {
      updateMemberRole: jest.fn(() => Promise.resolve()),
    };

    return new Vuex.Store({
      modules: {
        [MEMBER_TYPES.user]: { namespaced: true, actions },
      },
    });
  };

  const createComponent = (propsData = {}) => {
    wrapper = mount(RoleDropdown, {
      provide: {
        namespace: MEMBER_TYPES.user,
      },
      propsData: {
        member,
        permissions: {},
        ...propsData,
      },
      localVue,
      store: createStore(),
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
      .findAll(GlDropdownItem)
      .wrappers.find((dropdownItemWrapper) => dropdownItemWrapper.props('isChecked'));

  const findDropdownToggle = () => wrapper.find('button[aria-haspopup="true"]');
  const findDropdown = () => wrapper.find(GlDropdown);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when dropdown is open', () => {
    beforeEach((done) => {
      createComponent();

      findDropdownToggle().trigger('click');
      wrapper.vm.$root.$on(BV_DROPDOWN_SHOW, () => {
        done();
      });
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
      it('does nothing if the item selected was already selected', () => {
        getDropdownItemByText('Owner').trigger('click');

        expect(actions.updateMemberRole).not.toHaveBeenCalled();
      });

      it('calls `updateMemberRole` Vuex action', () => {
        getDropdownItemByText('Developer').trigger('click');

        expect(actions.updateMemberRole).toHaveBeenCalledWith(expect.any(Object), {
          memberId: member.id,
          accessLevel: { integerValue: 30, stringValue: 'Developer' },
        });
      });

      it('displays toast when successful', async () => {
        getDropdownItemByText('Developer').trigger('click');

        await waitForPromises();

        expect($toast.show).toHaveBeenCalledWith('Role updated successfully.');
      });

      it('disables dropdown while waiting for `updateMemberRole` to resolve', async () => {
        getDropdownItemByText('Developer').trigger('click');

        await nextTick();

        expect(findDropdown().props('disabled')).toBe(true);

        await waitForPromises();

        expect(findDropdown().props('disabled')).toBe(false);
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
});
