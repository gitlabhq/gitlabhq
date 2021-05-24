import {
  GlFilteredSearchToken,
  GlFilteredSearchTokenSegment,
  GlFilteredSearchSuggestion,
  GlDropdownDivider,
  GlLoadingIcon,
} from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import { deprecatedCreateFlash as createFlash } from '~/flash';
import axios from '~/lib/utils/axios_utils';

import {
  DEFAULT_LABEL_ANY,
  DEFAULT_NONE_ANY,
} from '~/vue_shared/components/filtered_search_bar/constants';
import AuthorToken from '~/vue_shared/components/filtered_search_bar/tokens/author_token.vue';

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

function createComponent(options = {}) {
  const {
    config = mockAuthorToken,
    value = { data: '' },
    active = false,
    stubs = defaultStubs,
    data = {},
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
  });
}

describe('AuthorToken', () => {
  const originalGon = window.gon;
  const currentUserLength = 1;
  let mock;
  let wrapper;

  beforeEach(() => {
    window.gon = {
      ...originalGon,
      current_user_id: 13,
      current_user_fullname: 'Administrator',
      current_username: 'root',
      current_user_avatar_url: 'avatar/url',
    };
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    window.gon = originalGon;
    mock.restore();
    wrapper.destroy();
  });

  describe('computed', () => {
    describe('currentValue', () => {
      it('returns lowercase string for `value.data`', () => {
        wrapper = createComponent({ value: { data: 'FOO' } });

        expect(wrapper.vm.currentValue).toBe('foo');
      });
    });

    describe('activeAuthor', () => {
      it('returns object for currently present `value.data`', async () => {
        wrapper = createComponent({ value: { data: mockAuthors[0].username } });

        wrapper.setData({
          authors: mockAuthors,
        });

        await wrapper.vm.$nextTick();

        expect(wrapper.vm.activeAuthor).toEqual(mockAuthors[0]);
      });
    });
  });

  describe('fetchAuthorBySearchTerm', () => {
    it('calls `config.fetchAuthors` with provided searchTerm param', () => {
      wrapper = createComponent();

      jest.spyOn(wrapper.vm.config, 'fetchAuthors');

      wrapper.vm.fetchAuthorBySearchTerm(mockAuthors[0].username);

      expect(wrapper.vm.config.fetchAuthors).toHaveBeenCalledWith(
        mockAuthorToken.fetchPath,
        mockAuthors[0].username,
      );
    });

    it('sets response to `authors` when request is succesful', () => {
      wrapper = createComponent();

      jest.spyOn(wrapper.vm.config, 'fetchAuthors').mockResolvedValue(mockAuthors);

      wrapper.vm.fetchAuthorBySearchTerm('root');

      return waitForPromises().then(() => {
        expect(wrapper.vm.authors).toEqual(mockAuthors);
      });
    });

    it('calls `createFlash` with flash error message when request fails', () => {
      wrapper = createComponent();

      jest.spyOn(wrapper.vm.config, 'fetchAuthors').mockRejectedValue({});

      wrapper.vm.fetchAuthorBySearchTerm('root');

      return waitForPromises().then(() => {
        expect(createFlash).toHaveBeenCalledWith('There was a problem fetching users.');
      });
    });

    it('sets `loading` to false when request completes', () => {
      wrapper = createComponent();

      jest.spyOn(wrapper.vm.config, 'fetchAuthors').mockRejectedValue({});

      wrapper.vm.fetchAuthorBySearchTerm('root');

      return waitForPromises().then(() => {
        expect(wrapper.vm.loading).toBe(false);
      });
    });
  });

  describe('template', () => {
    it('renders gl-filtered-search-token component', () => {
      wrapper = createComponent({ data: { authors: mockAuthors } });

      expect(wrapper.find(GlFilteredSearchToken).exists()).toBe(true);
    });

    it('renders token item when value is selected', () => {
      wrapper = createComponent({
        value: { data: mockAuthors[0].username },
        data: { authors: mockAuthors },
      });

      return wrapper.vm.$nextTick(() => {
        const tokenSegments = wrapper.findAll(GlFilteredSearchTokenSegment);

        expect(tokenSegments).toHaveLength(3); // Author, =, "Administrator"
        expect(tokenSegments.at(2).text()).toBe(mockAuthors[0].name); // "Administrator"
      });
    });

    it('renders provided defaultAuthors as suggestions', async () => {
      const defaultAuthors = DEFAULT_NONE_ANY;
      wrapper = createComponent({
        active: true,
        config: { ...mockAuthorToken, defaultAuthors },
        stubs: { Portal: true },
      });
      const tokenSegments = wrapper.findAll(GlFilteredSearchTokenSegment);
      const suggestionsSegment = tokenSegments.at(2);
      suggestionsSegment.vm.$emit('activate');
      await wrapper.vm.$nextTick();

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
        config: { ...mockAuthorToken },
        stubs: { Portal: true },
      });
      const tokenSegments = wrapper.findAll(GlFilteredSearchTokenSegment);
      const suggestionsSegment = tokenSegments.at(2);
      suggestionsSegment.vm.$emit('activate');
      await wrapper.vm.$nextTick();

      const suggestions = wrapper.findAll(GlFilteredSearchSuggestion);

      expect(suggestions).toHaveLength(1 + currentUserLength);
      expect(suggestions.at(0).text()).toBe(DEFAULT_LABEL_ANY.text);
    });

    describe('when loading', () => {
      beforeEach(() => {
        wrapper = createComponent({
          active: true,
          config: { ...mockAuthorToken, defaultAuthors: [] },
          stubs: { Portal: true },
        });
      });

      it('shows loading icon', () => {
        expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
      });

      it('shows current user', () => {
        const firstSuggestion = wrapper.findComponent(GlFilteredSearchSuggestion).text();
        expect(firstSuggestion).toContain('Administrator');
        expect(firstSuggestion).toContain('@root');
      });
    });
  });
});
