import {
  GlFilteredSearchTokenSegment,
  GlFilteredSearchSuggestion,
  GlDropdownDivider,
  GlAvatar,
} from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';

import {
  DEFAULT_LABEL_ANY,
  DEFAULT_NONE_ANY,
} from '~/vue_shared/components/filtered_search_bar/constants';
import AuthorToken from '~/vue_shared/components/filtered_search_bar/tokens/author_token.vue';
import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';

import { mockAuthorToken, mockAuthors } from '../mock_data';

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

const mockPreloadedAuthors = [
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
  return mount(AuthorToken, {
    propsData: {
      config,
      value,
      active,
    },
    provide: {
      portalName: 'fake target',
      alignSuggestions: function fakeAlignSuggestions() {},
      suggestionsListClass: 'custom-class',
    },
    data() {
      return { ...data };
    },
    stubs,
    listeners,
  });
}

describe('AuthorToken', () => {
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
    describe('fetchAuthorBySearchTerm', () => {
      beforeEach(() => {
        wrapper = createComponent();
      });

      it('calls `config.fetchAuthors` with provided searchTerm param', () => {
        jest.spyOn(wrapper.vm.config, 'fetchAuthors');

        getBaseToken().vm.$emit('fetch-suggestions', mockAuthors[0].username);

        expect(wrapper.vm.config.fetchAuthors).toHaveBeenCalledWith(
          mockAuthorToken.fetchPath,
          mockAuthors[0].username,
        );
      });

      it('sets response to `authors` when request is succesful', () => {
        jest.spyOn(wrapper.vm.config, 'fetchAuthors').mockResolvedValue(mockAuthors);

        getBaseToken().vm.$emit('fetch-suggestions', 'root');

        return waitForPromises().then(() => {
          expect(getBaseToken().props('suggestions')).toEqual(mockAuthors);
        });
      });

      it('calls `createFlash` with flash error message when request fails', () => {
        jest.spyOn(wrapper.vm.config, 'fetchAuthors').mockRejectedValue({});

        getBaseToken().vm.$emit('fetch-suggestions', 'root');

        return waitForPromises().then(() => {
          expect(createFlash).toHaveBeenCalledWith({
            message: 'There was a problem fetching users.',
          });
        });
      });

      it('sets `loading` to false when request completes', async () => {
        jest.spyOn(wrapper.vm.config, 'fetchAuthors').mockRejectedValue({});

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
      await wrapper.vm.$nextTick();
    };

    it('renders base-token component', () => {
      wrapper = createComponent({
        value: { data: mockAuthors[0].username },
        data: { authors: mockAuthors },
      });

      const baseTokenEl = getBaseToken();

      expect(baseTokenEl.exists()).toBe(true);
      expect(baseTokenEl.props()).toMatchObject({
        suggestions: mockAuthors,
        fnActiveTokenValue: wrapper.vm.getActiveAuthor,
      });
    });

    it('renders token item when value is selected', () => {
      wrapper = createComponent({
        value: { data: mockAuthors[0].username },
        data: { authors: mockAuthors },
        stubs: { Portal: true },
      });

      return wrapper.vm.$nextTick(() => {
        const tokenSegments = wrapper.findAll(GlFilteredSearchTokenSegment);

        expect(tokenSegments).toHaveLength(3); // Author, =, "Administrator"

        const tokenValue = tokenSegments.at(2);

        expect(tokenValue.findComponent(GlAvatar).props('src')).toBe(mockAuthors[0].avatar_url);
        expect(tokenValue.text()).toBe(mockAuthors[0].name); // "Administrator"
      });
    });

    it('renders token value with correct avatarUrl from author object', async () => {
      const getAvatarEl = () =>
        wrapper.findAll(GlFilteredSearchTokenSegment).at(2).findComponent(GlAvatar);

      wrapper = createComponent({
        value: { data: mockAuthors[0].username },
        data: {
          authors: [
            {
              ...mockAuthors[0],
            },
          ],
        },
        stubs: { Portal: true },
      });

      await wrapper.vm.$nextTick();

      expect(getAvatarEl().props('src')).toBe(mockAuthors[0].avatar_url);

      wrapper.setData({
        authors: [
          {
            ...mockAuthors[0],
            avatarUrl: mockAuthors[0].avatar_url,
            avatar_url: undefined,
          },
        ],
      });

      await wrapper.vm.$nextTick();

      expect(getAvatarEl().props('src')).toBe(mockAuthors[0].avatar_url);
    });

    it('renders provided defaultAuthors as suggestions', async () => {
      const defaultAuthors = DEFAULT_NONE_ANY;
      wrapper = createComponent({
        active: true,
        config: { ...mockAuthorToken, defaultAuthors, preloadedAuthors: mockPreloadedAuthors },
        stubs: { Portal: true },
      });

      await activateSuggestionsList();

      const suggestions = wrapper.findAll(GlFilteredSearchSuggestion);

      expect(suggestions).toHaveLength(defaultAuthors.length + currentUserLength);
      defaultAuthors.forEach((label, index) => {
        expect(suggestions.at(index).text()).toBe(label.text);
      });
    });

    it('does not render divider when no defaultAuthors', async () => {
      wrapper = createComponent({
        active: true,
        config: { ...mockAuthorToken, defaultAuthors: [] },
        stubs: { Portal: true },
      });
      const tokenSegments = wrapper.findAll(GlFilteredSearchTokenSegment);
      const suggestionsSegment = tokenSegments.at(2);
      suggestionsSegment.vm.$emit('activate');
      await wrapper.vm.$nextTick();

      expect(wrapper.find(GlDropdownDivider).exists()).toBe(false);
    });

    it('renders `DEFAULT_LABEL_ANY` as default suggestions', async () => {
      wrapper = createComponent({
        active: true,
        config: { ...mockAuthorToken, preloadedAuthors: mockPreloadedAuthors },
        stubs: { Portal: true },
      });

      await activateSuggestionsList();

      const suggestions = wrapper.findAll(GlFilteredSearchSuggestion);

      expect(suggestions).toHaveLength(1 + currentUserLength);
      expect(suggestions.at(0).text()).toBe(DEFAULT_LABEL_ANY.text);
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
            preloadedAuthors: mockPreloadedAuthors,
            defaultAuthors: [],
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

        await wrapper.vm.$nextTick();

        expect(wrapper.findComponent(GlFilteredSearchSuggestion).exists()).toBe(false);
      });
    });
  });
});
