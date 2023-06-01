import fuzzaldrinPlus from 'fuzzaldrin-plus';
import { GlDisclosureDropdownGroup, GlDisclosureDropdownItem, GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import CommandPaletteItems from '~/super_sidebar/components/global_search/command_palette/command_palette_items.vue';
import {
  COMMAND_HANDLE,
  COMMANDS_GROUP_TITLE,
  USERS_GROUP_TITLE,
  USER_HANDLE,
} from '~/super_sidebar/components/global_search/command_palette/constants';
import { userMapper } from '~/super_sidebar/components/global_search/command_palette/utils';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import waitForPromises from 'helpers/wait_for_promises';
import { COMMANDS, USERS } from './mock_data';

const commands = COMMANDS.map(({ text, href, keywords }) => ({
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
        commandPaletteData: COMMANDS,
      },
    });
  };

  const findItems = () => wrapper.findAllComponents(GlDisclosureDropdownItem);
  const findGroup = () => wrapper.findComponent(GlDisclosureDropdownGroup);
  const findLoader = () => wrapper.findComponent(GlLoadingIcon);

  describe('COMMANDS', () => {
    it('renders all commands initially', () => {
      createComponent();
      expect(findItems()).toHaveLength(COMMANDS.length);
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

      it('should display no results message when no command matched the search query', async () => {
        jest.spyOn(fuzzaldrinPlus, 'filter').mockReturnValue([]);
        createComponent({ searchQuery: 'mr' });
        const searchQuery = 'todo';
        await wrapper.setProps({ searchQuery });
        expect(wrapper.text()).toBe('No results found');
      });
    });
  });

  describe('USERS', () => {
    let mockAxios;

    beforeEach(() => {
      mockAxios = new MockAdapter(axios);
    });

    it('should NOT start search for users by the search query which is less than 3 chars', () => {
      jest.spyOn(axios, 'get');
      const searchQuery = 'us';
      createComponent({ handle: USER_HANDLE, searchQuery });

      expect(axios.get).not.toHaveBeenCalled();

      expect(findLoader().exists()).toBe(false);
    });

    it('should start search for users by the search query with 3+ chars and display a loader', () => {
      jest.spyOn(axios, 'get');
      const searchQuery = 'user';
      createComponent({ handle: USER_HANDLE, searchQuery });

      expect(axios.get).toHaveBeenCalledWith(
        expect.any(String),
        expect.objectContaining({
          params: {
            search: searchQuery,
          },
        }),
      );

      expect(findLoader().exists()).toBe(true);
    });

    it('should render returned users', async () => {
      mockAxios.onGet().replyOnce(HTTP_STATUS_OK, USERS);

      const searchQuery = 'user';
      createComponent({ handle: USER_HANDLE, searchQuery });

      await waitForPromises();
      expect(findItems()).toHaveLength(USERS.length);
      expect(findGroup().props('group')).toEqual({
        name: USERS_GROUP_TITLE,
        items: USERS.map(userMapper),
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
