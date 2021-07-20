import { GlFilteredSearchSuggestion, GlLoadingIcon, GlToken } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';

import TagToken, { TAG_SUGGESTIONS_PATH } from '~/runner/components/search_tokens/tag_token.vue';
import { OPERATOR_IS_ONLY } from '~/vue_shared/components/filtered_search_bar/constants';
import { getRecentlyUsedSuggestions } from '~/vue_shared/components/filtered_search_bar/filtered_search_utils';

jest.mock('~/flash');

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
  recentTokenValuesStorageKey: mockStorageKey,
  operators: OPERATOR_IS_ONLY,
};

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
        alignSuggestions: function fakeAlignSuggestions() {},
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

  beforeEach(async () => {
    mock = new MockAdapter(axios);

    mock.onGet(TAG_SUGGESTIONS_PATH, { params: { search: '' } }).reply(200, mockTags);
    mock
      .onGet(TAG_SUGGESTIONS_PATH, { params: { search: mockSearchTerm } })
      .reply(200, mockTagsFiltered);

    getRecentlyUsedSuggestions.mockReturnValue([]);

    createComponent();
    await waitForPromises();
  });

  afterEach(() => {
    getRecentlyUsedSuggestions.mockReset();
    wrapper.destroy();
  });

  describe('when the tags token is displayed', () => {
    it('requests tags suggestions', () => {
      expect(mock.history.get[0].params).toEqual({ search: '' });
    });

    it('displays tags suggestions', () => {
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
      expect(getRecentlyUsedSuggestions).toHaveBeenCalledWith(mockStorageKey);
    });

    it('displays stored tags suggestions', () => {
      expect(findGlFilteredSearchSuggestions()).toHaveLength(
        mockTags.length + storedSuggestions.length,
      );

      expect(findGlFilteredSearchSuggestions().at(0).text()).toBe(storedSuggestions[0].text);
    });
  });

  describe('when the users filters suggestions', () => {
    beforeEach(async () => {
      findGlFilteredSearchToken().vm.$emit('input', { data: mockSearchTerm });

      jest.runAllTimers();
    });

    it('requests filtered tags suggestions', async () => {
      await waitForPromises();

      expect(mock.history.get[1].params).toEqual({ search: mockSearchTerm });
    });

    it('shows the loading icon', async () => {
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
      mock.onGet(TAG_SUGGESTIONS_PATH, { params: { search: '' } }).reply(500);

      createComponent();
      await waitForPromises();
    });

    it('error is shown', async () => {
      expect(createFlash).toHaveBeenCalledTimes(1);
      expect(createFlash).toHaveBeenCalledWith({ message: expect.any(String) });
    });
  });

  describe('when the user selects a value', () => {
    beforeEach(async () => {
      createComponent({ value: { data: mockTags[0].name } });
      findGlFilteredSearchToken().vm.$emit('select');

      await waitForPromises();
    });

    it('selected tag is displayed', async () => {
      expect(findToken().exists()).toBe(true);
    });
  });
});
