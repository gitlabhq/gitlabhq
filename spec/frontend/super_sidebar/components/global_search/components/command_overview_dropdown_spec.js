import { GlListboxItem, GlSprintf, GlCollapsibleListbox } from '@gitlab/ui';
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
        GlCollapsibleListbox,
        GlListboxItem,
        GlSprintf,
      },
    });
  };

  const findDropdown = () => wrapper.findComponent(GlCollapsibleListbox);
  const findItems = () => wrapper.findAllComponents(GlListboxItem);
  const findItemTitles = () =>
    findItems().wrappers.map((w) => w.find('[data-testid="listbox-item-text"]').text());

  beforeEach(() => {
    createComponent();
  });

  describe('template', () => {
    it('renders header', () => {
      expect(findDropdown().find('[data-testid="listbox-header-text"]').text()).toBe(
        'I’m looking for',
      );
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
      findDropdown().vm.$emit('select', '@');
      expect(wrapper.emitted('selected')).toEqual([['@']]);
    });
  });
});
