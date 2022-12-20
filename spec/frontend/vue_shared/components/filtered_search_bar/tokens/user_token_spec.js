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
import { createAlert } from '~/flash';
import axios from '~/lib/utils/axios_utils';

import { OPTIONS_NONE_ANY } from '~/vue_shared/components/filtered_search_bar/constants';
import UserToken from '~/vue_shared/components/filtered_search_bar/tokens/user_token.vue';
import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';

import { mockAuthorToken, mockUsers } from '../mock_data';

jest.mock('~/flash');
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
    },
    data() {
      return { ...data };
    },
    stubs,
    listeners,
  });
}

describe('UserToken', () => {
  const originalGon = window.gon;
  const currentUserLength = 1;
  let mock;
  let wrapper;

  const getBaseToken = () => wrapper.findComponent(BaseToken);

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    window.gon = originalGon;
    mock.restore();
    wrapper.destroy();
  });

  describe('methods', () => {
    describe('fetchUsers', () => {
      beforeEach(() => {
        wrapper = createComponent();
      });

      it('calls `config.fetchUsers` with provided searchTerm param', () => {
        jest.spyOn(wrapper.vm.config, 'fetchUsers');

        getBaseToken().vm.$emit('fetch-suggestions', mockUsers[0].username);

        expect(wrapper.vm.config.fetchUsers).toHaveBeenCalledWith(
          mockAuthorToken.fetchPath,
          mockUsers[0].username,
        );
      });

      it('sets response to `users` when request is successful', () => {
        jest.spyOn(wrapper.vm.config, 'fetchUsers').mockResolvedValue(mockUsers);

        getBaseToken().vm.$emit('fetch-suggestions', 'root');

        return waitForPromises().then(() => {
          expect(getBaseToken().props('suggestions')).toEqual(mockUsers);
        });
      });

      // TODO: rm when completed https://gitlab.com/gitlab-org/gitlab/-/issues/345756
      describe('when there are null users presents', () => {
        const mockUsersWithNullUser = mockUsers.concat([null]);

        beforeEach(() => {
          jest
            .spyOn(wrapper.vm.config, 'fetchUsers')
            .mockResolvedValue({ data: mockUsersWithNullUser });

          getBaseToken().vm.$emit('fetch-suggestions', 'root');
        });

        describe('when res.data is present', () => {
          it('filters the successful response when null values are present', () => {
            return waitForPromises().then(() => {
              expect(getBaseToken().props('suggestions')).toEqual(mockUsers);
            });
          });
        });

        describe('when response is an array', () => {
          it('filters the successful response when null values are present', () => {
            return waitForPromises().then(() => {
              expect(getBaseToken().props('suggestions')).toEqual(mockUsers);
            });
          });
        });
      });

      it('calls `createAlert` with flash error message when request fails', () => {
        jest.spyOn(wrapper.vm.config, 'fetchUsers').mockRejectedValue({});

        getBaseToken().vm.$emit('fetch-suggestions', 'root');

        return waitForPromises().then(() => {
          expect(createAlert).toHaveBeenCalledWith({
            message: 'There was a problem fetching users.',
          });
        });
      });

      it('sets `loading` to false when request completes', async () => {
        jest.spyOn(wrapper.vm.config, 'fetchUsers').mockRejectedValue({});

        getBaseToken().vm.$emit('fetch-suggestions', 'root');

        await waitForPromises();

        expect(getBaseToken().props('suggestionsLoading')).toBe(false);
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

      const baseTokenEl = getBaseToken();

      expect(baseTokenEl.exists()).toBe(true);
      expect(baseTokenEl.props()).toMatchObject({
        suggestions: mockUsers,
        getActiveTokenValue: wrapper.vm.getActiveUser,
      });
    });

    it('renders token item when value is selected', async () => {
      wrapper = createComponent({
        value: { data: mockUsers[0].username },
        data: { users: mockUsers },
        stubs: { Portal: true },
      });

      await nextTick();
      const tokenSegments = wrapper.findAllComponents(GlFilteredSearchTokenSegment);

      expect(tokenSegments).toHaveLength(3); // Author, =, "Administrator"

      const tokenValue = tokenSegments.at(2);

      expect(tokenValue.findComponent(GlAvatar).props('src')).toBe(mockUsers[0].avatar_url);
      expect(tokenValue.text()).toBe(mockUsers[0].name); // "Administrator"
    });

    it('renders token value with correct avatarUrl from user object', async () => {
      const getAvatarEl = () =>
        wrapper.findAllComponents(GlFilteredSearchTokenSegment).at(2).findComponent(GlAvatar);

      wrapper = createComponent({
        value: { data: mockUsers[0].username },
        data: {
          users: [
            {
              ...mockUsers[0],
            },
          ],
        },
        stubs: { Portal: true },
      });

      await nextTick();

      expect(getAvatarEl().props('src')).toBe(mockUsers[0].avatar_url);

      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({
        users: [
          {
            ...mockUsers[0],
            avatarUrl: mockUsers[0].avatar_url,
            avatar_url: undefined,
          },
        ],
      });

      await nextTick();

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
        stubs: { Portal: true },
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
