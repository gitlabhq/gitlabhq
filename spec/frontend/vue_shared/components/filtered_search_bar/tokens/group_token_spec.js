import { GlFilteredSearchTokenSegment } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';

import groupAutocompleteQuery from '~/graphql_shared/queries/groups_autocomplete.query.graphql';
import searchGroupsQuery from '~/boards/graphql/sub_groups.query.graphql';
import GroupToken from '~/vue_shared/components/filtered_search_bar/tokens/group_token.vue';
import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';

import { mockGroupToken, mockGroups, mockGroupResponse, mockSubGroups } from '../mock_data';

Vue.use(VueApollo);

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

const groupsAutocompleteQueryHandler = jest.fn().mockResolvedValue(mockGroupResponse);
const subGroupsQueryHandler = jest.fn().mockResolvedValue(mockSubGroups);
const mockApollo = createMockApollo([
  [groupAutocompleteQuery, groupsAutocompleteQueryHandler],
  [searchGroupsQuery, subGroupsQueryHandler],
]);

function createComponent(options = {}) {
  const {
    config = mockGroupToken,
    value = { data: '' },
    active = false,
    stubs = defaultStubs,
    data = {},
    listeners = {},
    apollo = mockApollo,
  } = options;

  return mount(GroupToken, {
    apolloProvider: apollo,
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

describe('GroupToken', () => {
  let mock;
  let wrapper;

  const findBaseToken = () => wrapper.findComponent(BaseToken);

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
    createAlert.mockClear();
  });

  describe('methods', () => {
    describe('fetchGroupsBySearchTerm', () => {
      const triggerFetchGroups = (searchTerm = null) => {
        findBaseToken().vm.$emit('fetch-suggestions', searchTerm);
        waitForPromises();
      };

      it('sets base token to loading state per default', async () => {
        wrapper = createComponent({});

        await nextTick();

        expect(findBaseToken().props('suggestionsLoading')).toBe(true);
      });

      describe('when request is successful', () => {
        const searchTerm = 'box';

        beforeEach(async () => {
          wrapper = createComponent({
            config: {
              ...mockGroupToken,
              tokenType: 'All',
            },
          });
          triggerFetchGroups(searchTerm);
          await waitForPromises();
        });

        it('calls `fetchGroups` with provided searchTerm param', () => {
          expect(groupsAutocompleteQueryHandler).toHaveBeenCalledWith({ search: searchTerm });
        });

        it('sets response to `Groups` when request is successful', async () => {
          await nextTick();
          expect(findBaseToken().props('suggestions')).toEqual(mockGroups);
        });

        it('sets `loading` to false when request completes', async () => {
          await nextTick();
          expect(findBaseToken().props('suggestionsLoading')).toBe(false);
        });
      });

      describe('when request fails', () => {
        const apollo = createMockApollo([[groupAutocompleteQuery, jest.fn().mockRejectedValue()]]);

        beforeEach(async () => {
          wrapper = createComponent({
            config: {
              ...mockGroupToken,
              tokenType: 'All',
            },
            apollo,
          });
          triggerFetchGroups();
          await waitForPromises();
          await nextTick();
        });

        it('calls `createAlert`', () => {
          expect(createAlert).toHaveBeenCalledWith({
            message: 'There was a problem fetching groups.',
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
        ...mockGroupToken,
        config: {
          tokenType: 'All',
        },
        value: { data: 'toolbox/drawer/box' },
        data: { groups: mockGroups },
      });
      activateSuggestionsList();
      const baseTokenEl = findBaseToken();

      expect(baseTokenEl.props()).toMatchObject({
        suggestions: [
          {
            fullPath: 'toolbox/drawer/box',
          },
          {
            fullPath: 'Commit451',
          },
        ],
        valueIdentifier: expect.any(Function),
        getActiveTokenValue: expect.any(Function),
      });
    });

    describe('groups_autocomplete query', () => {
      it('renders token item when value is selected', async () => {
        wrapper = createComponent({
          ...mockGroupToken,
          config: {
            skipIdPrefix: true,
            queryHandler: groupsAutocompleteQueryHandler,
            tokenType: 'All',
          },
          value: { data: 'toolbox/drawer/box' },
          data: { groups: mockGroups },
        });

        await nextTick();

        activateSuggestionsList();
        const tokenSegments = wrapper.findAllComponents(GlFilteredSearchTokenSegment);
        expect(tokenSegments).toHaveLength(3);
        const tokenValue = tokenSegments.at(2);
        expect(tokenValue.text()).toBe('toolbox/drawer/box');
      });
    });

    describe('sub_groups query', () => {
      it('renders token item when value is selected', async () => {
        wrapper = createComponent({
          ...mockGroupToken,
          value: { data: 'Code Suggestions Group' },
          data: { groups: mockSubGroups },
          config: {
            queryHandler: subGroupsQueryHandler,
          },
        });

        await nextTick();

        activateSuggestionsList();
        const tokenSegments = wrapper.findAllComponents(GlFilteredSearchTokenSegment);
        expect(tokenSegments).toHaveLength(3);
        const tokenValue = tokenSegments.at(2);
        expect(tokenValue.text()).toBe('Code Suggestions Group');
      });
    });
  });
});
