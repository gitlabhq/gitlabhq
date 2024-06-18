import { GlFilteredSearchSuggestion, GlLoadingIcon, GlToken } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import TagToken from '~/ci/runner/components/search_tokens/tag_token.vue';
import { OPERATORS_IS } from '~/vue_shared/components/filtered_search_bar/constants';
import { getRecentlyUsedSuggestions } from '~/vue_shared/components/filtered_search_bar/filtered_search_utils';

jest.mock('~/alert');

jest.mock('~/vue_shared/components/filtered_search_bar/filtered_search_utils', () => ({
  ...jest.requireActual('~/vue_shared/components/filtered_search_bar/filtered_search_utils'),
  getRecentlyUsedSuggestions: jest.fn(),
}));

const mockStorageKey = 'stored-recent-tags';

const mockTags = [
  { id: 1, name: 'linux' },
  { id: 2, name: 'windows' },
  { id: 3, name: 'mac' },
];

const mockTagsFiltered = [mockTags[0]];

const mockSearchTerm = mockTags[0].name;

const GlFilteredSearchTokenStub = {
  template: `<div>
    <slot name="view-token"></slot>
    <slot name="suggestions"></slot>
  </div>`,
};

const mockTagTokenConfig = {
  icon: 'tag',
  title: 'Tags',
  type: 'tag',
  token: TagToken,
  recentSuggestionsStorageKey: mockStorageKey,
  operators: OPERATORS_IS,
};

const mockTagSuggestionsPath = '/path/runners/tag_list';

describe('TagToken', () => {
  let mock;
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = mount(TagToken, {
      propsData: {
        config: mockTagTokenConfig,
        value: { data: '' },
        active: false,
        ...props,
      },
      provide: {
        portalName: 'fake target',
        tagSuggestionsPath: mockTagSuggestionsPath,
        alignSuggestions: function fakeAligxnSuggestions() {},
        filteredSearchSuggestionListInstance: {
          register: jest.fn(),
          unregister: jest.fn(),
        },
      },
      stubs: {
        GlFilteredSearchToken: GlFilteredSearchTokenStub,
      },
    });
  };

  const findGlFilteredSearchSuggestions = () =>
    wrapper.findAllComponents(GlFilteredSearchSuggestion);
  const findGlFilteredSearchToken = () => wrapper.findComponent(GlFilteredSearchTokenStub);
  const findToken = () => wrapper.findComponent(GlToken);
  const findGlLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

  beforeEach(() => {
    mock = new MockAdapter(axios);

    mock.onGet(mockTagSuggestionsPath, { params: { search: '' } }).reply(HTTP_STATUS_OK, mockTags);
    mock
      .onGet(mockTagSuggestionsPath, { params: { search: mockSearchTerm } })
      .reply(HTTP_STATUS_OK, mockTagsFiltered);

    getRecentlyUsedSuggestions.mockReturnValue([]);
  });

  afterEach(() => {
    getRecentlyUsedSuggestions.mockReset();
  });

  describe('when the tags token is displayed', () => {
    beforeEach(() => {
      createComponent();
    });

    it('requests tags suggestions', () => {
      expect(mock.history.get[0].params).toEqual({ search: '' });
    });

    it('displays tags suggestions', async () => {
      await waitForPromises();

      mockTags.forEach(({ name }, i) => {
        expect(findGlFilteredSearchSuggestions().at(i).text()).toBe(name);
      });
    });
  });

  describe('when suggestions are stored', () => {
    const storedSuggestions = [{ id: 4, value: 'docker', text: 'docker' }];

    beforeEach(async () => {
      getRecentlyUsedSuggestions.mockReturnValue(storedSuggestions);

      createComponent();
      await waitForPromises();
    });

    it('suggestions are loaded from a correct key', () => {
      expect(getRecentlyUsedSuggestions).toHaveBeenCalledWith(
        mockStorageKey,
        expect.anything(),
        expect.anything(),
      );
    });

    it('displays stored tags suggestions', () => {
      expect(findGlFilteredSearchSuggestions()).toHaveLength(
        mockTags.length + storedSuggestions.length,
      );

      expect(findGlFilteredSearchSuggestions().at(0).text()).toBe(storedSuggestions[0].text);
    });
  });

  describe('when the users filters suggestions', () => {
    beforeEach(() => {
      createComponent();

      findGlFilteredSearchToken().vm.$emit('input', { data: mockSearchTerm });
    });

    it('requests filtered tags suggestions', () => {
      expect(mock.history.get[1].params).toEqual({ search: mockSearchTerm });
    });

    it('shows the loading icon', async () => {
      findGlFilteredSearchToken().vm.$emit('input', { data: mockSearchTerm });
      await nextTick();

      expect(findGlLoadingIcon().exists()).toBe(true);
    });

    it('displays filtered tags suggestions', async () => {
      await waitForPromises();

      expect(findGlFilteredSearchSuggestions()).toHaveLength(mockTagsFiltered.length);

      expect(findGlFilteredSearchSuggestions().at(0).text()).toBe(mockTagsFiltered[0].name);
    });
  });

  describe('when suggestions cannot be loaded', () => {
    beforeEach(async () => {
      mock
        .onGet(mockTagSuggestionsPath, { params: { search: '' } })
        .reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);

      createComponent();
      await waitForPromises();
    });

    it('error is shown', () => {
      expect(createAlert).toHaveBeenCalledTimes(1);
      expect(createAlert).toHaveBeenCalledWith({ message: expect.any(String) });
    });
  });

  describe('when the user selects a value', () => {
    beforeEach(async () => {
      createComponent({ value: { data: mockTags[0].name } });
      findGlFilteredSearchToken().vm.$emit('select');

      await waitForPromises();
    });

    it('selected tag is displayed', () => {
      expect(findToken().exists()).toBe(true);
    });
  });

  describe('when suggestions are disabled', () => {
    beforeEach(async () => {
      createComponent({
        config: {
          ...mockTagTokenConfig,
          suggestionsDisabled: true,
        },
      });

      await waitForPromises();
    });

    it('displays no suggestions', () => {
      expect(findGlFilteredSearchSuggestions()).toHaveLength(0);
      expect(mock.history.get).toHaveLength(0);
    });
  });
});
