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

import { createAlert } from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { OPTIONS_NONE_ANY } from '~/vue_shared/components/filtered_search_bar/constants';
import BranchToken from '~/vue_shared/components/filtered_search_bar/tokens/branch_token.vue';

import { mockBranches, mockBranchToken } from '../mock_data';

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
    },
    stubs,
  });
}

describe('BranchToken', () => {
  let mock;
  let wrapper;

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
    wrapper.destroy();
  });

  describe('methods', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    describe('fetchBranches', () => {
      it('calls `config.fetchBranches` with provided searchTerm param', () => {
        jest.spyOn(wrapper.vm.config, 'fetchBranches');

        wrapper.vm.fetchBranches('foo');

        expect(wrapper.vm.config.fetchBranches).toHaveBeenCalledWith('foo');
      });

      it('sets response to `branches` when request is succesful', () => {
        jest.spyOn(wrapper.vm.config, 'fetchBranches').mockResolvedValue({ data: mockBranches });

        wrapper.vm.fetchBranches('foo');

        return waitForPromises().then(() => {
          expect(wrapper.vm.branches).toEqual(mockBranches);
        });
      });

      it('calls `createAlert` with flash error message when request fails', () => {
        jest.spyOn(wrapper.vm.config, 'fetchBranches').mockRejectedValue({});

        wrapper.vm.fetchBranches('foo');

        return waitForPromises().then(() => {
          expect(createAlert).toHaveBeenCalledWith({
            message: 'There was a problem fetching branches.',
          });
        });
      });

      it('sets `loading` to false when request completes', () => {
        jest.spyOn(wrapper.vm.config, 'fetchBranches').mockRejectedValue({});

        wrapper.vm.fetchBranches('foo');

        return waitForPromises().then(() => {
          expect(wrapper.vm.loading).toBe(false);
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

    beforeEach(async () => {
      wrapper = createComponent({ value: { data: mockBranches[0].name } });

      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({
        branches: mockBranches,
      });

      await nextTick();
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
