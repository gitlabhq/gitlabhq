import fuzzaldrinPlus from 'fuzzaldrin-plus';
import { GlDisclosureDropdownGroup, GlDisclosureDropdownItem, GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import CommandPaletteItems from '~/super_sidebar/components/global_search/command_palette/command_palette_items.vue';
import {
  COMMAND_HANDLE,
  USERS_GROUP_TITLE,
  USER_HANDLE,
  SEARCH_SCOPE,
} from '~/super_sidebar/components/global_search/command_palette/constants';
import {
  commandMapper,
  linksReducer,
} from '~/super_sidebar/components/global_search/command_palette/utils';
import { getFormattedItem } from '~/super_sidebar/components/global_search/utils';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import waitForPromises from 'helpers/wait_for_promises';
import { COMMANDS, LINKS, USERS } from './mock_data';

const links = LINKS.reduce(linksReducer, []);

describe('CommandPaletteItems', () => {
  let wrapper;
  const autocompletePath = '/autocomplete';
  const searchContext = { project: { id: 1 }, group: { id: 2 } };

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
        commandPaletteCommands: COMMANDS,
        commandPaletteLinks: LINKS,
        autocompletePath,
        searchContext,
      },
    });
  };

  const findItems = () => wrapper.findAllComponents(GlDisclosureDropdownItem);
  const findGroups = () => wrapper.findAllComponents(GlDisclosureDropdownGroup);
  const findLoader = () => wrapper.findComponent(GlLoadingIcon);

  describe('COMMANDS & LINKS', () => {
    it('renders all commands initially', () => {
      createComponent();
      const commandGroup = COMMANDS.map(commandMapper)[0];
      expect(findItems()).toHaveLength(commandGroup.items.length);
      expect(findGroups().at(0).props('group')).toEqual({
        name: commandGroup.name,
        items: commandGroup.items,
      });
    });

    describe('with search query', () => {
      it('should filter commands and links by the search query', async () => {
        jest.spyOn(fuzzaldrinPlus, 'filter');
        createComponent({ searchQuery: 'mr' });
        const searchQuery = 'todo';
        await wrapper.setProps({ searchQuery });
        const commandGroup = COMMANDS.map(commandMapper)[0];
        expect(fuzzaldrinPlus.filter).toHaveBeenCalledWith(
          commandGroup.items,
          searchQuery,
          expect.objectContaining({ key: 'text' }),
        );
        expect(fuzzaldrinPlus.filter).toHaveBeenCalledWith(
          links,
          searchQuery,
          expect.objectContaining({ key: 'keywords' }),
        );
      });

      it('should display no results message when no command matched the search query', async () => {
        jest.spyOn(fuzzaldrinPlus, 'filter').mockReturnValue([]);
        createComponent({ searchQuery: 'mr' });
        const searchQuery = 'todo';
        await wrapper.setProps({ searchQuery });
        expect(wrapper.text()).toBe('No results found');
      });
    });
  });

  describe('USERS, ISSUES, PROJECTS', () => {
    let mockAxios;

    beforeEach(() => {
      mockAxios = new MockAdapter(axios);
    });

    it('should NOT start search by the search query which is less than 3 chars', () => {
      jest.spyOn(axios, 'get');
      const searchQuery = 'us';
      createComponent({ handle: USER_HANDLE, searchQuery });

      expect(axios.get).not.toHaveBeenCalled();

      expect(findLoader().exists()).toBe(false);
    });

    it('should start scoped search with 3+ chars and display a loader', () => {
      jest.spyOn(axios, 'get');
      const searchQuery = 'user';
      createComponent({ handle: USER_HANDLE, searchQuery });

      expect(axios.get).toHaveBeenCalledWith(
        `${autocompletePath}?term=${searchQuery}&project_id=${searchContext.project.id}&filter=search&scope=${SEARCH_SCOPE[USER_HANDLE]}`,
      );
      expect(findLoader().exists()).toBe(true);
    });

    it('should render returned items', async () => {
      mockAxios.onGet().replyOnce(HTTP_STATUS_OK, USERS);

      const searchQuery = 'user';
      createComponent({ handle: USER_HANDLE, searchQuery });

      await waitForPromises();
      expect(findItems()).toHaveLength(USERS.length);
      expect(findGroups().at(0).props('group')).toMatchObject({
        name: USERS_GROUP_TITLE,
        items: USERS.map(getFormattedItem),
      });
    });

    it('should display no results message when no users matched the search query', async () => {
      mockAxios.onGet().replyOnce(HTTP_STATUS_OK, []);
      const searchQuery = 'user';
      createComponent({ handle: USER_HANDLE, searchQuery });
      await waitForPromises();
      expect(wrapper.text()).toBe('No results found');
    });
  });
});
