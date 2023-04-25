import {
  GlFilteredSearchToken,
  GlFilteredSearchSuggestion,
  GlFilteredSearchTokenSegment,
  GlDropdownDivider,
} from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import waitForPromises from 'helpers/wait_for_promises';

import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { OPTIONS_NONE_ANY } from '~/vue_shared/components/filtered_search_bar/constants';
import BranchToken from '~/vue_shared/components/filtered_search_bar/tokens/branch_token.vue';
import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';

import { mockBranches, mockBranchToken } from '../mock_data';

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

function createComponent(options = {}) {
  const {
    config = mockBranchToken,
    value = { data: '' },
    active = false,
    stubs = defaultStubs,
  } = options;
  return mount(BranchToken, {
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
    stubs,
  });
}

describe('BranchToken', () => {
  let mock;
  let wrapper;

  const findBaseToken = () => wrapper.findComponent(BaseToken);
  const triggerFetchBranches = (searchTerm = null) => {
    findBaseToken().vm.$emit('fetch-suggestions', searchTerm);
    return waitForPromises();
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('methods', () => {
    describe('fetchBranches', () => {
      it('sets loading state', async () => {
        wrapper = createComponent({
          config: {
            fetchBranches: jest.fn().mockResolvedValue(new Promise(() => {})),
          },
        });
        await nextTick();

        expect(findBaseToken().props('suggestionsLoading')).toBe(true);
      });

      describe('when request is successful', () => {
        beforeEach(() => {
          wrapper = createComponent({
            config: {
              fetchBranches: jest.fn().mockResolvedValue({ data: mockBranches }),
            },
          });
        });

        it('calls `config.fetchBranches` with provided searchTerm param', async () => {
          const searchTerm = 'foo';
          await triggerFetchBranches(searchTerm);

          expect(findBaseToken().props('config').fetchBranches).toHaveBeenCalledWith(searchTerm);
        });

        it('sets response to `branches`', async () => {
          await triggerFetchBranches();

          expect(findBaseToken().props('suggestions')).toEqual(mockBranches);
        });

        it('sets `loading` to false when request completes', async () => {
          await triggerFetchBranches();

          expect(findBaseToken().props('suggestionsLoading')).toBe(false);
        });
      });

      describe('when request fails', () => {
        beforeEach(() => {
          wrapper = createComponent({
            config: {
              fetchBranches: jest.fn().mockRejectedValue({}),
            },
          });
        });

        it('calls `createAlert` with alert error message when request fails', async () => {
          await triggerFetchBranches();

          expect(createAlert).toHaveBeenCalledWith({
            message: 'There was a problem fetching branches.',
          });
        });

        it('sets `loading` to false when request completes', async () => {
          await triggerFetchBranches();

          expect(findBaseToken().props('suggestionsLoading')).toBe(false);
        });
      });
    });
  });

  describe('template', () => {
    const defaultBranches = OPTIONS_NONE_ANY;
    async function showSuggestions() {
      const tokenSegments = wrapper.findAllComponents(GlFilteredSearchTokenSegment);
      const suggestionsSegment = tokenSegments.at(2);
      suggestionsSegment.vm.$emit('activate');
      await nextTick();
    }

    beforeEach(() => {
      wrapper = createComponent({
        value: { data: mockBranches[0].name },
        config: {
          initialBranches: mockBranches,
        },
      });
    });

    it('renders gl-filtered-search-token component', () => {
      expect(wrapper.findComponent(GlFilteredSearchToken).exists()).toBe(true);
    });

    it('renders token item when value is selected', () => {
      const tokenSegments = wrapper.findAllComponents(GlFilteredSearchTokenSegment);

      expect(tokenSegments).toHaveLength(3);
      expect(tokenSegments.at(2).text()).toBe(mockBranches[0].name);
    });

    it('renders provided defaultBranches as suggestions', async () => {
      wrapper = createComponent({
        active: true,
        config: { ...mockBranchToken, defaultBranches },
        stubs: { Portal: true },
      });
      await showSuggestions();
      const suggestions = wrapper.findAllComponents(GlFilteredSearchSuggestion);

      expect(suggestions).toHaveLength(defaultBranches.length);
      defaultBranches.forEach((branch, index) => {
        expect(suggestions.at(index).text()).toBe(branch.text);
      });
    });

    it('does not render divider when no defaultBranches', async () => {
      wrapper = createComponent({
        active: true,
        config: { ...mockBranchToken, defaultBranches: [] },
        stubs: { Portal: true },
      });
      await showSuggestions();

      expect(wrapper.findComponent(GlFilteredSearchSuggestion).exists()).toBe(false);
      expect(wrapper.findComponent(GlDropdownDivider).exists()).toBe(false);
    });

    it('renders no suggestions as default', async () => {
      wrapper = createComponent({
        active: true,
        config: { ...mockBranchToken },
        stubs: { Portal: true },
      });
      await showSuggestions();
      const suggestions = wrapper.findAllComponents(GlFilteredSearchSuggestion);

      expect(suggestions).toHaveLength(0);
    });
  });
});
