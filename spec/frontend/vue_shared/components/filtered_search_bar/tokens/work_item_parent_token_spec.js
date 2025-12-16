import { GlDropdownDivider, GlFilteredSearchTokenSegment } from '@gitlab/ui';

import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { getIdFromGraphQLId, convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_WORK_ITEM } from '~/graphql_shared/constants';

import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';
import WorkItemParentToken from '~/vue_shared/components/filtered_search_bar/tokens/work_item_parent_token.vue';
import { OPTIONS_NONE_ANY } from '~/vue_shared/components/filtered_search_bar/constants';
import searchWorkItemParentQuery from '~/vue_shared/components/filtered_search_bar/queries/search_work_item_parent.query.graphql';

import {
  mockGroupParentWorkItemsQueryResponse,
  mockProjectParentWorkItemsQueryResponse,
} from '../mock_data';

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

describe('WorkItemParentToken', () => {
  Vue.use(VueApollo);

  let wrapper;

  const searchGroupWorkItemsParentQueryHandler = jest
    .fn()
    .mockResolvedValue(mockGroupParentWorkItemsQueryResponse);

  const searchProjectWorkItemsParentQueryHandler = jest
    .fn()
    .mockResolvedValue(mockProjectParentWorkItemsQueryResponse);

  const mockWorkItemParentToken = {
    type: 'parent',
    icon: 'link',
    title: 'Parent',
    unique: false,
    token: WorkItemParentToken,
    fullPath: 'gitlab-org/gitlab-test',
    isProject: true,
    initialWorkItems: [],
    defaultWorkItems: OPTIONS_NONE_ANY,
  };

  const createComponent = ({
    config = mockWorkItemParentToken,
    value = { data: '' },
    active = false,
    queryHandler = searchProjectWorkItemsParentQueryHandler,
    stubs = defaultStubs,
    mountFn = shallowMountExtended,
  } = {}) => {
    wrapper = mountFn(WorkItemParentToken, {
      apolloProvider: createMockApollo([[searchWorkItemParentQuery, queryHandler]]),
      propsData: {
        config,
        value,
        active,
      },
      provide: {
        portalName: 'fake target',
        alignSuggestions: function fakeAlignSuggestions() {},
        suggestionsListClass: () => 'custom-class',
        termsAsTokens: () => false,
      },
      stubs,
    });
  };

  const findBaseToken = () => wrapper.findComponent(BaseToken);
  const findViewSlot = () => wrapper.findAllByTestId('filtered-search-token-segment').at(2);
  const triggerFetchWorkItems = (searchTerm = null) => {
    findBaseToken().vm.$emit('fetch-suggestions', searchTerm);
    return waitForPromises();
  };

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('renders the component', () => {
    createComponent();

    expect(wrapper.findComponent(WorkItemParentToken).exists()).toBe(true);
  });

  describe('methods', () => {
    describe('fetchWorkItemsBySearchTerm', () => {
      it('sets loading state', async () => {
        createComponent({
          queryHandler: jest.fn().mockReturnValue(new Promise(() => {})),
        });

        findBaseToken().vm.$emit('fetch-suggestions', 'test');

        await waitForPromises();

        expect(findBaseToken().props('suggestionsLoading')).toBe(true);
      });

      describe('when request is successful', () => {
        const searchTerm = 'animals';

        beforeEach(() => {
          createComponent();
          return triggerFetchWorkItems(searchTerm);
        });

        it('calls searchWorkItemParentQuery with provided searchTerm param', () => {
          expect(searchProjectWorkItemsParentQueryHandler).toHaveBeenCalledWith({
            fullPath: 'gitlab-org/gitlab-test',
            groupPath: 'gitlab-org',
            search: searchTerm,
            in: 'TITLE',
            includeDescendants: false,
            includeAncestors: true,
            types: ['EPIC', 'OBJECTIVE', 'ISSUE'],
            isProject: true,
          });
        });

        it('sets response to `workItems`', () => {
          const expectedWorkItems = [
            ...mockProjectParentWorkItemsQueryResponse.data.group.workItems.nodes,
            ...mockProjectParentWorkItemsQueryResponse.data.project.workItems.nodes,
          ];
          expect(findBaseToken().props('suggestions')).toEqual(expectedWorkItems);
        });
      });

      describe('when request fails', () => {
        beforeEach(() => {
          createComponent({
            queryHandler: jest.fn().mockRejectedValue(new Error('Network error')),
          });
          return triggerFetchWorkItems();
        });

        it('calls `createAlert`', () => {
          expect(createAlert).toHaveBeenCalledWith({
            message: 'There was a problem fetching the parent items.',
          });
        });

        it('sets `loading` to false when request completes', () => {
          expect(findBaseToken().props('suggestionsLoading')).toBe(false);
        });
      });

      describe('for project context', () => {
        beforeEach(() => {
          const config = {
            ...mockWorkItemParentToken,
            fullPath: 'group/project',
            isProject: true,
          };
          createComponent({ config });
          return triggerFetchWorkItems();
        });

        it('calls query with correct project parameters', () => {
          expect(searchProjectWorkItemsParentQueryHandler).toHaveBeenCalledWith({
            fullPath: 'group/project',
            groupPath: 'group',
            search: null,
            in: undefined,
            includeDescendants: false,
            includeAncestors: true,
            types: ['EPIC', 'OBJECTIVE', 'ISSUE'],
            isProject: true,
          });
        });
      });

      describe('for group context', () => {
        beforeEach(() => {
          const config = {
            ...mockWorkItemParentToken,
            fullPath: 'group',
            isProject: false,
          };
          createComponent({ config, queryHandler: searchGroupWorkItemsParentQueryHandler });
          return triggerFetchWorkItems();
        });

        it('calls query with correct group parameters', () => {
          expect(searchGroupWorkItemsParentQueryHandler).toHaveBeenCalledWith({
            fullPath: 'group',
            groupPath: 'group',
            search: null,
            in: undefined,
            includeDescendants: true,
            includeAncestors: true,
            types: ['EPIC'],
            isProject: false,
          });
        });
      });

      describe('with search term', () => {
        const searchTerm = 'epic title';

        beforeEach(() => {
          createComponent();
          return triggerFetchWorkItems(searchTerm);
        });

        it('includes `in: TITLE` parameter when searching', () => {
          expect(searchProjectWorkItemsParentQueryHandler).toHaveBeenCalledWith({
            fullPath: 'gitlab-org/gitlab-test',
            groupPath: 'gitlab-org',
            search: searchTerm,
            in: 'TITLE',
            includeDescendants: false,
            includeAncestors: true,
            types: ['EPIC', 'OBJECTIVE', 'ISSUE'],
            isProject: true,
          });
        });
      });

      describe('with search term id', () => {
        const searchTerm = '132';

        beforeEach(() => {
          createComponent();
          return triggerFetchWorkItems(searchTerm);
        });

        it('queries by ids when searching with a numeric term', () => {
          expect(searchProjectWorkItemsParentQueryHandler).toHaveBeenCalledWith({
            fullPath: 'gitlab-org/gitlab-test',
            groupPath: 'gitlab-org',
            search: '',
            in: undefined,
            includeDescendants: false,
            includeAncestors: true,
            types: ['EPIC', 'OBJECTIVE', 'ISSUE'],
            isProject: true,
            ids: [convertToGraphQLId(TYPENAME_WORK_ITEM, searchTerm)],
          });
        });
      });
    });
  });

  describe('template', () => {
    const activateSuggestionsList = () => {
      const tokenSegments = wrapper.findAllComponents(GlFilteredSearchTokenSegment);
      const suggestionsSegment = tokenSegments.at(2);
      suggestionsSegment.vm.$emit('activate');
    };

    beforeEach(() => {
      const mockWorkItems = mockProjectParentWorkItemsQueryResponse.data.project.workItems.nodes;
      const config = {
        ...mockWorkItemParentToken,
        initialWorkItems: mockWorkItems,
      };
      createComponent({
        config,
        value: { data: getIdFromGraphQLId(mockWorkItems[0].iid).toString() },
        mountFn: mountExtended,
        stubs: { Portal: true },
      });
    });

    it('renders base-token component', () => {
      const baseTokenEl = findBaseToken();

      expect(baseTokenEl.exists()).toBe(true);
      expect(baseTokenEl.props()).toMatchObject({
        config: expect.objectContaining({
          type: 'parent',
          icon: 'link',
          title: 'Parent',
        }),
        suggestions: expect.any(Array),
        getActiveTokenValue: expect.any(Function),
        valueIdentifier: expect.any(Function),
      });
    });

    it('renders token item when value is selected', async () => {
      await activateSuggestionsList();

      expect(findViewSlot().text()).toBe('Order different types of grass');
    });

    it('renders provided defaultWorkItems as suggestions', () => {
      const defaultWorkItems = OPTIONS_NONE_ANY;
      const config = {
        ...mockWorkItemParentToken,
        defaultWorkItems,
      };
      createComponent({
        config,
        active: true,
        mountFn: mountExtended,
        stubs: { Portal: true },
      });

      findBaseToken().vm.$emit('fetch-suggestions', 'test');

      const baseToken = findBaseToken();
      expect(baseToken.props('defaultSuggestions')).toEqual(defaultWorkItems);
    });

    it('does not render divider when no defaultWorkItems', () => {
      const config = { ...mockWorkItemParentToken, defaultWorkItems: [] };
      createComponent({
        config,
        active: true,
        mountFn: mountExtended,
        stubs: { Portal: true },
      });

      findBaseToken().vm.$emit('fetch-suggestions', '');

      const baseToken = findBaseToken();
      expect(baseToken.props('defaultSuggestions')).toEqual([]);
      expect(wrapper.findComponent(GlDropdownDivider).exists()).toBe(false);
    });

    it('renders work item suggestions correctly', () => {
      const mockWorkItems = mockProjectParentWorkItemsQueryResponse.data.project.workItems.nodes;
      const config = {
        ...mockWorkItemParentToken,
        initialWorkItems: mockWorkItems,
      };
      createComponent({
        config,
        active: true,
        mountFn: mountExtended,
        stubs: { Portal: true },
      });

      findBaseToken().vm.$emit('fetch-suggestions', '');

      const baseToken = findBaseToken();
      expect(baseToken.props('suggestions')).toEqual(mockWorkItems);

      expect(baseToken.props('suggestions')).toHaveLength(1);
      expect(baseToken.props('suggestions')[0].title).toBe('Order different types of grass');
    });

    describe('suggestions list', () => {
      beforeEach(() => {
        const mockWorkItems = [
          {
            id: 'gid://gitlab/WorkItem/1',
            iid: '1',
            title: 'First Work Item',
          },
          {
            id: 'gid://gitlab/WorkItem/2',
            iid: '2',
            title: 'Second Work Item',
          },
          {
            id: 'gid://gitlab/WorkItem/3',
            iid: '3',
            title: 'Third Work Item',
          },
        ];

        createComponent({
          config: {
            ...mockWorkItemParentToken,
            initialWorkItems: mockWorkItems,
          },
          active: true,
          mountFn: mountExtended,
          stubs: { Portal: true },
        });
      });

      it('renders suggestions with work item titles', () => {
        findBaseToken().vm.$emit('fetch-suggestions', '');

        const baseToken = findBaseToken();
        expect(baseToken.props('suggestions')).toHaveLength(3);
        expect(baseToken.props('suggestions')[0].title).toBe('First Work Item');
        expect(baseToken.props('suggestions')[1].title).toBe('Second Work Item');
      });
    });
  });

  describe('when workItems response is empty', () => {
    beforeEach(() => {
      const emptyResponse = {
        data: {
          group: { workItems: { nodes: [] } },
          project: { workItems: { nodes: [] } },
        },
      };
      createComponent({
        queryHandler: jest.fn().mockResolvedValue(emptyResponse),
      });
      return triggerFetchWorkItems();
    });

    it('sets workItems to empty array', () => {
      expect(findBaseToken().props('suggestions')).toHaveLength(0);
    });
  });
});
