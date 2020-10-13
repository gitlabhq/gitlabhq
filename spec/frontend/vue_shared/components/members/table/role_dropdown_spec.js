import { mount, createWrapper } from '@vue/test-utils';
import { nextTick } from 'vue';
import { within } from '@testing-library/dom';
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { GlBreakpointInstance as bp } from '@gitlab/ui/dist/utils';
import RoleDropdown from '~/vue_shared/components/members/table/role_dropdown.vue';
import { member } from '../mock_data';

describe('RoleDropdown', () => {
  let wrapper;

  const createComponent = (propsData = {}) => {
    wrapper = mount(RoleDropdown, {
      propsData: {
        member,
        ...propsData,
      },
    });
  };

  const getDropdownMenu = () => within(wrapper.element).getByRole('menu');
  const getByTextInDropdownMenu = (text, options = {}) =>
    createWrapper(within(getDropdownMenu()).getByText(text, options));
  const getDropdownItemByText = text =>
    getByTextInDropdownMenu(text, { selector: '[role="menuitem"] p' });
  const getCheckedDropdownItem = () =>
    wrapper
      .findAll(GlDropdownItem)
      .wrappers.find(dropdownItemWrapper => dropdownItemWrapper.props('isChecked'));

  const findDropdownToggle = () => wrapper.find('button[aria-haspopup="true"]');
  const findDropdown = () => wrapper.find(GlDropdown);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when dropdown is open', () => {
    beforeEach(done => {
      createComponent();

      findDropdownToggle().trigger('click');
      wrapper.vm.$root.$on('bv::dropdown::shown', () => {
        done();
      });
    });

    it('renders all valid roles', () => {
      Object.keys(member.validRoles).forEach(role => {
        expect(getDropdownItemByText(role).exists()).toBe(true);
      });
    });

    it('renders dropdown header', () => {
      expect(getByTextInDropdownMenu('Change permissions').exists()).toBe(true);
    });

    it('sets dropdown toggle and checks selected role', async () => {
      expect(findDropdownToggle().text()).toBe('Owner');
      expect(getCheckedDropdownItem().text()).toBe('Owner');
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

    expect(findDropdown().attributes('right')).toBe('true');
  });

  it('sets the dropdown alignment to left on desktop', async () => {
    jest.spyOn(bp, 'isDesktop').mockReturnValue(true);
    createComponent();

    await nextTick();

    expect(findDropdown().attributes('right')).toBeUndefined();
  });
});
