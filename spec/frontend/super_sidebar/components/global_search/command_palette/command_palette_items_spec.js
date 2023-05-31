import fuzzaldrinPlus from 'fuzzaldrin-plus';
import { GlDisclosureDropdownGroup, GlDisclosureDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import CommandPaletteItems from '~/super_sidebar/components/global_search/command_palette/command_palette_items.vue';
import {
  COMMAND_HANDLE,
  COMMANDS_GROUP_TITLE,
} from '~/super_sidebar/components/global_search/command_palette/constants';
import { COMMAND_PALETTE_COMMANDS } from './mock_data';

const commands = COMMAND_PALETTE_COMMANDS.map(({ text, href, keywords }) => ({
  text,
  href,
  keywords: keywords.join(''),
}));

describe('CommandPaletteItems', () => {
  let wrapper;

  const createComponent = (props) => {
    wrapper = shallowMount(CommandPaletteItems, {
      propsData: {
        handle: COMMAND_HANDLE,
        searchQuery: '',
        ...props,
      },
      stubs: {
        GlDisclosureDropdownGroup,
        GlDisclosureDropdownItem,
      },
      provide: {
        commandPaletteData: COMMAND_PALETTE_COMMANDS,
      },
    });
  };

  const findItems = () => wrapper.findAllComponents(GlDisclosureDropdownItem);
  const findGroup = () => wrapper.findComponent(GlDisclosureDropdownGroup);

  it('renders all commands initially', () => {
    createComponent();
    expect(findItems()).toHaveLength(COMMAND_PALETTE_COMMANDS.length);
    expect(findGroup().props('group')).toEqual({
      name: COMMANDS_GROUP_TITLE,
      items: commands,
    });
  });

  describe('with search query', () => {
    it('should filter by the search query', async () => {
      jest.spyOn(fuzzaldrinPlus, 'filter');
      createComponent({ searchQuery: 'mr' });
      const searchQuery = 'todo';
      await wrapper.setProps({ searchQuery });
      expect(fuzzaldrinPlus.filter).toHaveBeenCalledWith(
        commands,
        searchQuery,
        expect.objectContaining({ key: 'keywords' }),
      );
    });

    it('should display no results message when no command matched the search qery', async () => {
      jest.spyOn(fuzzaldrinPlus, 'filter').mockReturnValue([]);
      createComponent({ searchQuery: 'mr' });
      const searchQuery = 'todo';
      await wrapper.setProps({ searchQuery });
      expect(wrapper.text()).toBe('No results found');
    });
  });
});
