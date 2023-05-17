import {
  GlFilteredSearchTokenSegment,
  GlFilteredSearchSuggestion,
  GlDropdownDivider,
  GlAvatar,
} from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';

import { OPTIONS_NONE_ANY } from '~/vue_shared/components/filtered_search_bar/constants';
import UserToken from '~/vue_shared/components/filtered_search_bar/tokens/user_token.vue';
import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';

import { mockAuthorToken, mockUsers } from '../mock_data';

jest.mock('~/alert');
const defaultStubs = {
  Portal: true,
  GlFilteredSearchSuggestionList: {
    template: '<div></div>',
    methods: {
      getValue: () => '=',
    },
  },
};

const mockPreloadedUsers = [
  {
    id: 13,
    name: 'Administrator',
    username: 'root',
    avatar_url: 'avatar/url',
  },
];

function createComponent(options = {}) {
  const {
    config = mockAuthorToken,
    value = { data: '' },
    active = false,
    stubs = defaultStubs,
    data = {},
    listeners = {},
  } = options;
  return mount(UserToken, {
    propsData: {
      config,
      value,
      active,
      cursorPosition: 'start',
    },
    provide: {
      portalName: 'fake target',
      alignSuggestions: function fakeAlignSuggestions() {},
      suggestionsListClass: () => 'custom-class',
      termsAsTokens: () => false,
    },
    data() {
      return { ...data };
    },
    stubs,
    listeners,
  });
}

describe('UserToken', () => {
  const currentUserLength = 1;
  let mock;
  let wrapper;

  const findBaseToken = () => wrapper.findComponent(BaseToken);

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('methods', () => {
    describe('fetchUsers', () => {
      const triggerFetchUsers = (searchTerm = null) => {
        findBaseToken().vm.$emit('fetch-suggestions', searchTerm);
        return waitForPromises();
      };

      beforeEach(() => {
        wrapper = createComponent();
      });

      it('sets loading state', async () => {
        wrapper = createComponent({
          config: {
            fetchUsers: jest.fn().mockResolvedValue(new Promise(() => {})),
          },
        });
        await nextTick();

        expect(findBaseToken().props('suggestionsLoading')).toBe(true);
      });

      describe('when request is successful', () => {
        const searchTerm = 'foo';

        beforeEach(() => {
          wrapper = createComponent({
            config: {
              fetchUsers: jest.fn().mockResolvedValue({ data: mockUsers }),
            },
          });
          return triggerFetchUsers(searchTerm);
        });

        it('calls `config.fetchUsers` with provided searchTerm param', () => {
          expect(findBaseToken().props('config').fetchUsers).toHaveBeenCalledWith(searchTerm);
        });

        it('sets response to `users` when request is successful', () => {
          expect(findBaseToken().props('suggestions')).toEqual(mockUsers);
        });
      });

      describe('when request fails', () => {
        beforeEach(() => {
          wrapper = createComponent({
            config: {
              fetchUsers: jest.fn().mockRejectedValue({}),
            },
          });
          return triggerFetchUsers();
        });

        it('calls `createAlert`', () => {
          expect(createAlert).toHaveBeenCalledWith({
            message: 'There was a problem fetching users.',
          });
        });

        it('sets `loading` to false when request completes', () => {
          expect(findBaseToken().props('suggestionsLoading')).toBe(false);
        });
      });
    });
  });

  describe('template', () => {
    const activateSuggestionsList = async () => {
      const tokenSegments = wrapper.findAllComponents(GlFilteredSearchTokenSegment);
      const suggestionsSegment = tokenSegments.at(2);
      suggestionsSegment.vm.$emit('activate');
      await nextTick();
    };

    it('renders base-token component', () => {
      wrapper = createComponent({
        value: { data: mockUsers[0].username },
        data: { users: mockUsers },
      });

      const baseTokenEl = findBaseToken();

      expect(baseTokenEl.exists()).toBe(true);
      expect(baseTokenEl.props()).toMatchObject({
        suggestions: mockUsers,
        getActiveTokenValue: baseTokenEl.props('getActiveTokenValue'),
      });
    });

    it('renders token item when value is selected', async () => {
      wrapper = createComponent({
        value: { data: mockUsers[0].username },
        data: { users: mockUsers },
      });

      await nextTick();
      const tokenSegments = wrapper.findAllComponents(GlFilteredSearchTokenSegment);

      expect(tokenSegments).toHaveLength(3); // Author, =, "Administrator"

      const tokenValue = tokenSegments.at(2);

      expect(tokenValue.findComponent(GlAvatar).props('src')).toBe(mockUsers[0].avatar_url);
      expect(tokenValue.text()).toBe(mockUsers[0].name); // "Administrator"
    });

    it('renders token value with correct avatarUrl from user object', () => {
      const getAvatarEl = () =>
        wrapper.findAllComponents(GlFilteredSearchTokenSegment).at(2).findComponent(GlAvatar);

      wrapper = createComponent({
        value: { data: mockUsers[0].username },
        data: {
          users: [
            {
              ...mockUsers[0],
              avatarUrl: mockUsers[0].avatar_url,
              avatar_url: undefined,
            },
          ],
        },
      });

      expect(getAvatarEl().props('src')).toBe(mockUsers[0].avatar_url);
    });

    it('renders provided defaultUsers as suggestions', async () => {
      const defaultUsers = OPTIONS_NONE_ANY;
      wrapper = createComponent({
        active: true,
        config: { ...mockAuthorToken, defaultUsers, preloadedUsers: mockPreloadedUsers },
        stubs: { Portal: true },
      });

      await activateSuggestionsList();

      const suggestions = wrapper.findAllComponents(GlFilteredSearchSuggestion);

      expect(suggestions).toHaveLength(defaultUsers.length + currentUserLength);
      defaultUsers.forEach((label, index) => {
        expect(suggestions.at(index).text()).toBe(label.text);
      });
    });

    it('does not render divider when no defaultUsers', async () => {
      wrapper = createComponent({
        active: true,
        config: { ...mockAuthorToken, defaultUsers: [] },
      });
      const tokenSegments = wrapper.findAllComponents(GlFilteredSearchTokenSegment);
      const suggestionsSegment = tokenSegments.at(2);
      suggestionsSegment.vm.$emit('activate');
      await nextTick();

      expect(wrapper.findComponent(GlDropdownDivider).exists()).toBe(false);
    });

    it('renders `OPTIONS_NONE_ANY` as default suggestions', async () => {
      wrapper = createComponent({
        active: true,
        config: { ...mockAuthorToken, preloadedUsers: mockPreloadedUsers },
        stubs: { Portal: true },
      });

      await activateSuggestionsList();

      const suggestions = wrapper.findAllComponents(GlFilteredSearchSuggestion);

      expect(suggestions).toHaveLength(2 + currentUserLength);
      expect(suggestions.at(0).text()).toBe(OPTIONS_NONE_ANY[0].text);
      expect(suggestions.at(1).text()).toBe(OPTIONS_NONE_ANY[1].text);
    });

    it('emits listeners in the base-token', () => {
      const mockInput = jest.fn();
      wrapper = createComponent({
        listeners: {
          input: mockInput,
        },
      });
      wrapper.findComponent(BaseToken).vm.$emit('input', [{ data: 'mockData', operator: '=' }]);

      expect(mockInput).toHaveBeenLastCalledWith([{ data: 'mockData', operator: '=' }]);
    });

    describe('when loading', () => {
      beforeEach(() => {
        wrapper = createComponent({
          active: true,
          config: {
            ...mockAuthorToken,
            preloadedUsers: mockPreloadedUsers,
            defaultUsers: [],
          },
          stubs: { Portal: true },
        });
      });

      it('shows current user', () => {
        const firstSuggestion = wrapper.findComponent(GlFilteredSearchSuggestion).text();
        expect(firstSuggestion).toContain('Administrator');
        expect(firstSuggestion).toContain('@root');
      });

      it('does not show current user while searching', async () => {
        wrapper.findComponent(BaseToken).vm.handleInput({ data: 'foo' });

        await nextTick();

        expect(wrapper.findComponent(GlFilteredSearchSuggestion).exists()).toBe(false);
      });
    });
  });
});
