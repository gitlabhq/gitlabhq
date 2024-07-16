import { GlCollapsibleListbox } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { roleDropdownItems } from '~/members/utils';
import RoleSelector from '~/members/components/role_selector.vue';
import { member } from '../mock_data';

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn(),
}));

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
  });
});
