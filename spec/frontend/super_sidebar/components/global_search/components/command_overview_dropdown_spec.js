import { GlDisclosureDropdown, GlSprintf, GlDisclosureDropdownItem } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CommandsOverviewDropdown from '~/super_sidebar/components/global_search/command_palette/command_overview_dropdown.vue';

describe('CommandsOverviewDropdown', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(CommandsOverviewDropdown, {
      propsData: {
        items: [
          {
            value: '>',
            text: 'Pages',
          },
          {
            value: '@',
            text: 'Users',
          },
          {
            value: ':',
            text: 'Projects',
          },
          {
            value: '~',
            text: 'Pages',
          },
        ],
      },
      stubs: {
        GlDisclosureDropdown,
        GlDisclosureDropdownItem,
        GlSprintf,
      },
    });
  };

  const findDropdow = () => wrapper.findComponent(GlDisclosureDropdown);
  const findItems = () => wrapper.findAllComponents(GlDisclosureDropdownItem);
  const findItemTitles = () =>
    findItems().wrappers.map((w) => w.find('[data-testid="disclosure-dropdown-item"]').text());

  beforeEach(() => {
    createComponent();
  });

  describe('template', () => {
    it('renders header', () => {
      expect(findDropdow().find('span').text()).toBe('I’m looking for');
    });

    it('renders all items', () => {
      expect(findItems()).toHaveLength(4);
    });

    it('renders item correctly', () => {
      expect(findItemTitles()).toHaveLength(4);
    });
  });

  describe('events', () => {
    it('renders header', () => {
      findDropdow().vm.$emit('action', { value: '@' });
      expect(wrapper.emitted('selected')).toEqual([['@']]);
    });
  });
});
