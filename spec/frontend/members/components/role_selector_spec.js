import { GlCollapsibleListbox } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { roleDropdownItems } from '~/members/utils';
import RoleSelector from '~/members/components/role_selector.vue';
import { member } from '../mock_data';

describe('Role selector', () => {
  const dropdownItems = roleDropdownItems(member);
  let wrapper;

  const createWrapper = ({
    roles = dropdownItems,
    value = dropdownItems.flatten[0],
    loading,
  } = {}) => {
    wrapper = mountExtended(RoleSelector, {
      propsData: { roles, value, loading },
    });
  };

  const findDropdown = () => wrapper.findComponent(GlCollapsibleListbox);
  const getDropdownItem = (id) => wrapper.findByTestId(`listbox-item-${id}`);
  const findRoleName = (id) => getDropdownItem(id).find('[data-testid="role-name"]');
  const findRoleDescription = (id) => getDropdownItem(id).find('[data-testid="role-description"]');

  describe('dropdown component', () => {
    it('shows the dropdown with the expected props', () => {
      createWrapper();

      expect(findDropdown().props()).toMatchObject({
        headerText: 'Change role',
        items: dropdownItems.formatted,
        selected: dropdownItems.flatten[0].value,
        loading: false,
        block: true,
      });
    });

    it.each([true, false])('passes the loading state %s to the dropdown', (loading) => {
      createWrapper({ loading });

      expect(findDropdown().props('loading')).toBe(loading);
    });

    it('passes the selected item to the dropdown', () => {
      createWrapper({ value: dropdownItems.flatten[5] });

      expect(findDropdown().props('selected')).toBe(dropdownItems.flatten[5].value);
    });

    it('emits selected role when role is changed', () => {
      createWrapper();
      findDropdown().vm.$emit('select', dropdownItems.flatten[5].value);

      expect(wrapper.emitted('input')[0][0]).toBe(dropdownItems.flatten[5]);
    });

    it('does not show manage role link', () => {
      createWrapper();

      expect(findDropdown().props('resetButtonLabel')).toBe('');
    });
  });

  describe('dropdown items', () => {
    beforeEach(() => {
      createWrapper();
    });

    it.each(dropdownItems.flatten)('shows the role name for $text', ({ value, text }) => {
      expect(findRoleName(value).text()).toBe(text);
    });

    it.each(dropdownItems.flatten.filter((item) => item.dropdownDescription))(
      'shows the dropdown description for base role $text',
      ({ value, dropdownDescription }) => {
        const description = findRoleDescription(value);

        expect(description.exists()).toBe(true);
        expect(description.text()).toBe(dropdownDescription);
      },
    );

    it('falls back to description when dropdownDescription is not present', () => {
      const itemWithDescription = {
        value: 'role-custom-99',
        text: 'Custom',
        accessLevel: 10,
        memberRoleId: 99,
        description: 'A custom role description',
      };
      const roles = {
        flatten: [itemWithDescription],
        formatted: [itemWithDescription],
      };

      createWrapper({ roles, value: itemWithDescription });

      const description = findRoleDescription('role-custom-99');

      expect(description.exists()).toBe(true);
      expect(description.text()).toBe('A custom role description');
    });

    it('does not show description for role without any description', () => {
      const itemWithoutDescription = {
        value: 'role-custom-100',
        text: 'Custom No Desc',
        accessLevel: 10,
        memberRoleId: 100,
      };
      const roles = {
        flatten: [itemWithoutDescription],
        formatted: [itemWithoutDescription],
      };

      createWrapper({ roles, value: itemWithoutDescription });

      const description = findRoleDescription('role-custom-100');

      expect(description.exists()).toBe(false);
    });
  });
});
