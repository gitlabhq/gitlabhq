import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlButton, GlCollapsibleListbox, GlLoadingIcon } from '@gitlab/ui';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent } from 'helpers/stub_component';
import waitForPromises from 'helpers/wait_for_promises';
import { TYPENAME_GROUP, TYPENAME_PROJECT } from '~/graphql_shared/constants';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import * as sentryBrowserWrapper from '~/sentry/sentry_browser_wrapper';
import {
  SCOPE_PICKER_ITEM_TYPE_GROUP,
  SCOPE_PICKER_ITEM_TYPE_PROJECT,
  SCOPE_PICKER_ITEM_TYPE_LOAD_MORE,
} from '~/explore/analytics_dashboards/components/constants';
import ScopePicker from '~/explore/analytics_dashboards/components/scope_picker.vue';
import ScopePickerItem from '~/explore/analytics_dashboards/components/scope_picker_item.vue';
import getSubgroupProjectsQuery from '~/explore/analytics_dashboards/graphql/get_subgroup_projects.query.graphql';
import getTopLevelGroupsQuery from '~/explore/analytics_dashboards/graphql/get_top_level_groups.query.graphql';
import searchNamespacesGlobalQuery from '~/explore/analytics_dashboards/graphql/search_namespaces_global.query.graphql';
import getScopeNamespaceQuery from '~/explore/analytics_dashboards/graphql/get_scope_namespace.query.graphql';
import getFrecentGroupsQuery from '~/explore/analytics_dashboards/graphql/get_frecent_groups.query.graphql';
import getOrganizationGroupQuery from '~/explore/analytics_dashboards/graphql/get_organization_group.query.graphql';

Vue.use(VueApollo);

jest.mock('~/sentry/sentry_browser_wrapper');

describe('ScopePicker', () => {
  let wrapper;
  let subgroupRequestHandler;
  let topLevelGroupsRequestHandler;
  let globalSearchRequestHandler;
  let scopeNamespaceRequestHandler;
  let frecentGroupsRequestHandler;
  let organizationGroupRequestHandler;

  const groupFullPath = 'gitlab-org';
  const closeListbox = jest.fn();

  const groupPermissions = (readProAiAnalytics = true) => ({
    __typename: 'GroupPermissions',
    readProAiAnalytics,
  });
  const projectPermissions = (readProAiAnalytics = true) => ({
    __typename: 'ProjectPermissions',
    readProAiAnalytics,
  });

  const mockGroup = {
    __typename: TYPENAME_GROUP,
    id: 'gid://gitlab/Group/1',
    name: 'GitLab.org',
    fullName: 'GitLab.org',
    fullPath: groupFullPath,
    userPermissions: groupPermissions(),
  };

  const mockProject = (id, name, path) => ({
    __typename: TYPENAME_PROJECT,
    id: `gid://gitlab/Project/${id}`,
    name,
    fullName: `GitLab.org / ${name}`,
    fullPath: `${groupFullPath}/${path}`,
    userPermissions: projectPermissions(),
  });

  const mockSubgroup = ({ id, name, path, projectsCount = 0, descendantGroupsCount = 0 }) => ({
    __typename: TYPENAME_GROUP,
    id: `gid://gitlab/Group/${id}`,
    name,
    fullName: `GitLab.org / ${name}`,
    fullPath: `${groupFullPath}/${path}`,
    userPermissions: groupPermissions(),
    projectsCount,
    descendantGroupsCount,
  });

  const mockFrontend = mockSubgroup({
    id: 10,
    name: 'Frontend',
    path: 'frontend',
    projectsCount: 1,
    descendantGroupsCount: 1,
  });

  const mockTools = {
    __typename: TYPENAME_GROUP,
    id: 'gid://gitlab/Group/12',
    name: 'Tools',
    fullPath: `${groupFullPath}/frontend/tools`,
  };

  // One project directly in the expanded subgroup, one from a subgroup nested below it.
  const mockSubgroupProjects = [
    {
      ...mockProject(3, 'GitLab UI', 'frontend/gitlab-ui'),
      namespace: {
        __typename: TYPENAME_GROUP,
        id: mockFrontend.id,
        name: mockFrontend.name,
        fullPath: mockFrontend.fullPath,
      },
    },
    {
      ...mockProject(4, 'Design tools', 'frontend/tools/design'),
      namespace: mockTools,
    },
  ];

  const mockTopLevelGroup = ({ id, name, path, projectsCount = 0, descendantGroupsCount = 0 }) => ({
    __typename: TYPENAME_GROUP,
    id: `gid://gitlab/Group/${id}`,
    name,
    fullName: name,
    fullPath: path,
    userPermissions: groupPermissions(),
    projectsCount,
    descendantGroupsCount,
  });

  const mockCapsuleCorp = mockTopLevelGroup({
    id: 20,
    name: 'Capsule Corp',
    path: 'capsule-corp',
    projectsCount: 2,
    descendantGroupsCount: 1,
  });
  const mockAcme = mockTopLevelGroup({ id: 21, name: 'Acme Inc', path: 'acme' });
  const mockTopLevelGroups = [mockCapsuleCorp, mockAcme];

  const mockCapsuleProjects = [
    {
      __typename: TYPENAME_PROJECT,
      id: 'gid://gitlab/Project/30',
      name: 'Time Machine',
      fullName: 'Capsule Corp / Time Machine',
      fullPath: 'capsule-corp/time-machine',
      userPermissions: projectPermissions(),
      namespace: {
        __typename: TYPENAME_GROUP,
        id: mockCapsuleCorp.id,
        name: mockCapsuleCorp.name,
        fullPath: mockCapsuleCorp.fullPath,
      },
    },
    // Sits a level down, so the flattened list has to say which subgroup it came from.
    {
      __typename: TYPENAME_PROJECT,
      id: 'gid://gitlab/Project/31',
      name: 'Gravity Chamber',
      fullName: 'Capsule Corp / Research / Gravity Chamber',
      fullPath: 'capsule-corp/research/gravity-chamber',
      userPermissions: projectPermissions(),
      namespace: {
        __typename: TYPENAME_GROUP,
        id: 'gid://gitlab/Group/23',
        name: 'Research',
        fullPath: 'capsule-corp/research',
      },
    },
  ];

  const mockUmbrellaCorp = mockTopLevelGroup({
    id: 22,
    name: 'Umbrella Corp',
    path: 'umbrella-corp',
  });

  const mockExtraCapsuleProject = {
    __typename: TYPENAME_PROJECT,
    id: 'gid://gitlab/Project/32',
    name: 'Dragon Radar',
    fullName: 'Capsule Corp / Dragon Radar',
    fullPath: 'capsule-corp/dragon-radar',
    userPermissions: projectPermissions(),
    namespace: {
      __typename: TYPENAME_GROUP,
      id: mockCapsuleCorp.id,
      name: mockCapsuleCorp.name,
      fullPath: mockCapsuleCorp.fullPath,
    },
  };

  // Deep enough that no amount of browsing reaches it, which is the point of search.
  const mockDeepSubgroup = {
    __typename: TYPENAME_GROUP,
    id: 'gid://gitlab/Group/40',
    name: 'Design system',
    fullName: 'GitLab.org / Frontend / Design system',
    fullPath: `${groupFullPath}/frontend/design-system`,
    userPermissions: groupPermissions(),
    namespace: {
      __typename: TYPENAME_GROUP,
      id: mockFrontend.id,
      name: mockFrontend.name,
      fullPath: mockFrontend.fullPath,
    },
  };

  const mockDeepProject = {
    ...mockProject(41, 'Pajamas', 'frontend/design-system/pajamas'),
    namespace: {
      __typename: TYPENAME_GROUP,
      id: mockDeepSubgroup.id,
      name: mockDeepSubgroup.name,
      fullPath: mockDeepSubgroup.fullPath,
    },
  };

  // What a different term matches, sharing nothing with the results above.
  const mockUnrelatedProject = {
    ...mockProject(42, 'Charts', 'charts'),
    namespace: {
      __typename: TYPENAME_GROUP,
      id: mockGroup.id,
      name: mockGroup.name,
      fullPath: mockGroup.fullPath,
    },
  };

  const searchResponse = ({ groups = [mockDeepSubgroup], projects = [mockDeepProject] } = {}) => ({
    data: {
      groups: { __typename: 'GroupConnection', nodes: groups },
      projects: { __typename: 'ProjectConnection', nodes: projects },
    },
  });

  const respondWithGlobalSearch = (results) => jest.fn().mockResolvedValue(searchResponse(results));

  // A project the `scope` URL param can name that browsing never lists, the browse connections
  // being capped at 20.
  const mockScopeProject = {
    __typename: TYPENAME_PROJECT,
    id: 'gid://gitlab/Project/51',
    name: 'Runner',
    fullName: 'GitLab.org / Runner',
    fullPath: `${groupFullPath}/runner`,
    userPermissions: projectPermissions(),
  };

  const respondWithScopeNamespace = ({ group = null, projects = [] } = {}) =>
    jest.fn().mockResolvedValue({
      data: {
        group,
        projects: { __typename: 'ProjectConnection', nodes: projects },
      },
    });

  // The picker asks per path, so the handler answers with whatever that one path names.
  const respondWithScopeNamespaces = (namespacesByPath = {}) =>
    jest.fn().mockImplementation(({ fullPath }) => {
      const namespace = namespacesByPath[fullPath] ?? null;
      const { __typename: typename } = namespace ?? {};
      const isProject = typename === TYPENAME_PROJECT;

      return Promise.resolve({
        data: {
          group: isProject ? null : namespace,
          projects: {
            __typename: 'ProjectConnection',
            nodes: isProject ? [namespace] : [],
          },
        },
      });
    });

  // A page names the cursor the next one starts from, so naming one is what says there is more.
  const pageInfo = (endCursor) => ({
    __typename: 'PageInfo',
    hasNextPage: Boolean(endCursor),
    endCursor: endCursor ?? null,
  });

  const topLevelGroupsPage = (groups = mockTopLevelGroups, endCursor = null) => ({
    data: {
      groups: { __typename: 'GroupConnection', nodes: groups, pageInfo: pageInfo(endCursor) },
    },
  });

  // Ordered by frecency, so the first is the one a default is derived from.
  const respondWithFrecentGroups = (frecentGroups = []) =>
    jest.fn().mockResolvedValue({ data: { frecentGroups } });

  // Empty nodes are how the connection reports a group the page's organization does not hold.
  const respondWithOrganizationGroup = (groups = []) =>
    jest.fn().mockResolvedValue({
      data: {
        organization: {
          __typename: 'Organization',
          id: 'gid://gitlab/Organizations::Organization/1',
          groups: { __typename: 'GroupConnection', nodes: groups },
        },
      },
    });

  const subgroupProjectsPage = (projects = mockSubgroupProjects, endCursor = null) => ({
    data: {
      group: {
        __typename: TYPENAME_GROUP,
        id: mockFrontend.id,
        projects: {
          __typename: 'ProjectConnection',
          nodes: projects,
          pageInfo: pageInfo(endCursor),
        },
      },
    },
  });

  const respondWithTopLevelGroups = (groups, endCursor) =>
    jest.fn().mockResolvedValue(topLevelGroupsPage(groups, endCursor));

  const respondWithSubgroupProjects = (projects, endCursor) =>
    jest.fn().mockResolvedValue(subgroupProjectsPage(projects, endCursor));

  const asNamespace = ({ id, name, fullName, fullPath, __typename }) => ({
    id,
    name,
    fullName,
    fullPath,
    type: __typename,
    restricted: false,
  });

  // The real listbox takes either grouped sections or a flat option list, rendering its
  // list-item slot per option either way.
  const listboxStub = stubComponent(GlCollapsibleListbox, {
    template: `
      <div>
        <div v-for="(item, index) in flatItems" :key="item.value || index">
          <slot name="list-item" :item="item"></slot>
        </div>
        <div data-testid="listbox-search-summary">
          <slot name="search-summary-sr-only"></slot>
        </div>
        <slot name="footer"></slot>
      </div>`,
    computed: {
      flatItems() {
        return this.items.flatMap((item) => item.options ?? item);
      },
    },
    methods: { close: closeListbox },
  });

  const createWrapper = ({
    subgroupHandler = respondWithSubgroupProjects(mockCapsuleProjects),
    topLevelGroupsHandler = respondWithTopLevelGroups(),
    globalSearchHandler = respondWithGlobalSearch(),
    scopeNamespaceHandler = respondWithScopeNamespace(),
    frecentGroupsHandler = respondWithFrecentGroups(),
    organizationGroupHandler = respondWithOrganizationGroup(),
    props = {},
    listeners = {},
  } = {}) => {
    subgroupRequestHandler = subgroupHandler;
    topLevelGroupsRequestHandler = topLevelGroupsHandler;
    globalSearchRequestHandler = globalSearchHandler;
    scopeNamespaceRequestHandler = scopeNamespaceHandler;
    frecentGroupsRequestHandler = frecentGroupsHandler;
    organizationGroupRequestHandler = organizationGroupHandler;

    wrapper = shallowMountExtended(ScopePicker, {
      apolloProvider: createMockApollo([
        [getSubgroupProjectsQuery, subgroupRequestHandler],
        [getTopLevelGroupsQuery, topLevelGroupsRequestHandler],
        [searchNamespacesGlobalQuery, globalSearchRequestHandler],
        [getScopeNamespaceQuery, scopeNamespaceRequestHandler],
        [getFrecentGroupsQuery, frecentGroupsRequestHandler],
        [getOrganizationGroupQuery, organizationGroupRequestHandler],
      ]),
      propsData: { multiSelect: true, ...props },
      listeners,
      stubs: { GlCollapsibleListbox: listboxStub },
    });
  };

  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findSections = () => findListbox().props('items');
  const findOptions = () => findSections().flatMap((item) => item.options ?? item);
  const findDoneButton = () => wrapper.findComponent(GlButton);
  const findItems = () => wrapper.findAllComponents(ScopePickerItem);
  const findEmptyItem = () => wrapper.findByTestId('scope-picker-empty-item');
  const findSearchSummary = () => wrapper.findByTestId('listbox-search-summary');
  const findItemFor = ({ fullPath }) =>
    findItems().wrappers.find((item) => item.props('value') === fullPath);
  const findItemTexts = () => findItems().wrappers.map((item) => item.props('text'));
  const findItemValues = () => findItems().wrappers.map((item) => item.props('value'));
  const findSectionNames = () => findSections().map(({ text }) => text);
  const findSectionOptions = (name) =>
    findSections().find(({ text }) => text === name)?.options ?? [];
  // Pinned rows are told apart by the section they sit in, so how their values are built stays
  // the component's own business.
  const findPinnedOptions = () => findSectionOptions('Selected');
  const findPinnedValues = () => findPinnedOptions().map(({ value }) => value);
  const findPinnedItems = () =>
    findItems().wrappers.filter((item) => findPinnedValues().includes(item.props('value')));
  const findListValues = () => findSectionOptions('Groups and projects').map(({ value }) => value);
  const expectFlatList = () =>
    expect(findSections().every(({ options }) => options === undefined)).toBe(true);
  const findLoadMoreItems = () =>
    findItems().wrappers.filter(
      (item) => item.props('itemType') === SCOPE_PICKER_ITEM_TYPE_LOAD_MORE,
    );
  // The list's own row sits at the end of everything; a group's sits at the end of its projects.
  const findListLoadMore = () => findLoadMoreItems().find((item) => !item.props('nested'));
  const findGroupLoadMore = () => findLoadMoreItems().find((item) => item.props('nested'));

  // Naming nothing and ticking nothing is what the page turns into its empty state.
  const expectEmptyState = () => {
    expect(findListbox().props('selected')).toEqual([]);
    expect(findListbox().props('toggleText')).toBe('Select a group or project');
  };

  // Mirrors what the listbox emits on click: the whole selection, with the clicked item toggled.
  const toggleSelected = ({ fullPath }) => {
    const selected = findListbox().props('selected');
    const paths = selected.includes(fullPath)
      ? selected.filter((path) => path !== fullPath)
      : [...selected, fullPath];

    return findListbox().vm.$emit('select', paths);
  };
  const toggleExpanded = (namespace = mockGroup) =>
    findItemFor(namespace).vm.$emit('toggle-expanded');

  // Each click reports the selection the listbox currently renders,
  // so a pick has to land before the next one reads it.
  const selectAll = (...namespaces) =>
    namespaces.reduce(
      (previousPicks, namespace) => previousPicks.then(() => toggleSelected(namespace)),
      Promise.resolve(),
    );

  // Every pick is pinned above the list, loaded below or not, so that is where they are read.
  const findSelectedNames = () => findPinnedOptions().map(({ text }) => text);
  const untickPinned = (name) =>
    toggleSelected({ fullPath: findPinnedOptions().find(({ text }) => text === name).value });

  // Multi-select picks only reach the consumer once the listbox closes.
  const hideListbox = () => findListbox().vm.$emit('hidden');

  const findSlotsLeft = () => wrapper.findByTestId('scope-picker-slots-left');

  // `emitted()` keeps no order across events, so record them as they arrive.
  const recordEvents = () => {
    const events = [];
    const listeners = {
      change: () => events.push('change'),
      ready: () => events.push('ready'),
    };

    return { events, listeners };
  };

  const expectReadyOnce = () => expect(wrapper.emitted('ready')).toEqual([[]]);

  // The listbox owns the search input, so typing arrives as an event. The handler is debounced.
  const search = async (term) => {
    findListbox().vm.$emit('search', term);
    jest.advanceTimersByTime(DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
    await waitForPromises();
  };

  describe('browsing', () => {
    describe('while loading', () => {
      beforeEach(() => createWrapper());

      it('requests the top-level groups', () => {
        expect(topLevelGroupsRequestHandler).toHaveBeenCalled();
      });

      it('sets the listbox to loading', () => {
        expect(findListbox().props('loading')).toBe(true);
      });

      it('announces no count before the first page of groups arrives', () => {
        expect(findSearchSummary().text()).toBe('');
      });
    });

    describe('once loaded', () => {
      beforeEach(async () => {
        createWrapper();
        await waitForPromises();
      });

      it('stops loading', () => {
        expect(findListbox().props('loading')).toBe(false);
      });

      it('lists the groups flat, with no section headers to label a single kind of row', () => {
        expect(findSections().every(({ options }) => options === undefined)).toBe(true);
        expect(findOptions().map(({ value, text }) => ({ value, text }))).toEqual([
          { value: mockCapsuleCorp.fullPath, text: mockCapsuleCorp.name },
          { value: mockAcme.fullPath, text: mockAcme.name },
        ]);
      });

      it('announces how many groups are listed while browsing', () => {
        expect(findSearchSummary().text()).toBe('2 results');
      });

      it('nests nothing, since every row is a group until one is expanded', () => {
        expect(findItems().wrappers.map((item) => item.props('nested'))).toEqual([false, false]);
      });

      it('starts nothing expanded, there being no group the view is about', () => {
        expect(findItems().wrappers.map((item) => item.props('expanded'))).toEqual([false, false]);
      });

      describe('expanding a group', () => {
        beforeEach(() => toggleExpanded(mockCapsuleCorp));

        it('asks for every project beneath it, however deep', () => {
          expect(subgroupRequestHandler).toHaveBeenCalledWith({
            fullPath: mockCapsuleCorp.fullPath,
            after: null,
          });
        });

        it('marks the group as expanding while the request is in flight', () => {
          expect(findItemFor(mockCapsuleCorp).props('expanding')).toBe(true);
        });

        describe('once its projects arrive', () => {
          beforeEach(() => waitForPromises());

          it('reveals them beneath the group', () => {
            expect(findItems().wrappers.map((item) => item.props('value'))).toEqual([
              mockCapsuleCorp.fullPath,
              ...mockCapsuleProjects.map(({ fullPath }) => fullPath),
              mockAcme.fullPath,
            ]);
          });

          it('renders them flat, whatever their real depth', () => {
            expect(findItems().wrappers.filter((item) => item.props('nested'))).toHaveLength(
              mockCapsuleProjects.length,
            );
          });

          // Only the ones that did not come straight from the expanded group need saying.
          it('names the parent only for a project sitting below the group', () => {
            expect(findItemFor(mockCapsuleProjects[0]).props('parentName')).toBeNull();
            expect(findItemFor(mockCapsuleProjects[1]).props('parentName')).toBe('Research');
          });

          it('does not refetch when collapsed and expanded again', async () => {
            await toggleExpanded(mockCapsuleCorp);
            await toggleExpanded(mockCapsuleCorp);
            await waitForPromises();

            expect(subgroupRequestHandler).toHaveBeenCalledTimes(1);
          });

          it('locks the projects once the group itself is selected', async () => {
            await toggleSelected(mockCapsuleCorp);

            expect(findItemFor(mockCapsuleProjects[0]).props('disabled')).toBe(true);
            expect(findItemFor(mockCapsuleProjects[0]).props('selected')).toBe(true);
          });

          // Their rows render checked, so the options behind them have to be selected as well.
          it('counts the locked projects as selected, alongside the group itself', async () => {
            await toggleSelected(mockCapsuleCorp);

            expect(findListbox().props('selected')).toEqual([
              ...findPinnedValues(),
              mockCapsuleCorp.fullPath,
              ...mockCapsuleProjects.map(({ fullPath }) => fullPath),
            ]);
          });

          it('leaves the group indeterminate when one of its projects is selected', async () => {
            await toggleSelected(mockCapsuleProjects[0]);

            expect(findItemFor(mockCapsuleCorp).props('indeterminate')).toBe(true);
            expect(findItemFor(mockCapsuleCorp).props('selected')).toBe(false);
          });

          it('keeps the toggle text after the group it came from is collapsed', async () => {
            await toggleSelected(mockCapsuleProjects[0]);
            await toggleExpanded(mockCapsuleCorp);

            expect(findListbox().props('toggleText')).toBe(mockCapsuleProjects[0].name);
          });
        });
      });

      it('emits the selected group', async () => {
        await toggleSelected(mockCapsuleCorp);
        await hideListbox();

        expect(wrapper.emitted('change')).toEqual([[[asNamespace(mockCapsuleCorp)]]]);
      });
    });

    it.each`
      beneath                     | projectsCount | descendantGroupsCount | expandable
      ${'projects and subgroups'} | ${2}          | ${1}                  | ${true}
      ${'only projects'}          | ${2}          | ${0}                  | ${true}
      ${'only subgroups'}         | ${0}          | ${1}                  | ${true}
      ${'nothing'}                | ${0}          | ${0}                  | ${false}
    `(
      'sets expandable to $expandable on a top-level group with $beneath beneath it',
      async ({ projectsCount, descendantGroupsCount, expandable }) => {
        const group = mockTopLevelGroup({
          id: 30,
          name: 'Umbrella Corp',
          path: 'umbrella-corp',
          projectsCount,
          descendantGroupsCount,
        });

        createWrapper({ topLevelGroupsHandler: respondWithTopLevelGroups([group]) });
        await waitForPromises();

        expect(findItemFor(group).props('expandable')).toBe(expandable);
      },
    );

    describe('when an expanded group turns out to have no projects', () => {
      beforeEach(async () => {
        createWrapper({ subgroupHandler: respondWithSubgroupProjects([]) });
        await waitForPromises();
        await toggleExpanded(mockCapsuleCorp);
        await waitForPromises();
      });

      it('renders a placeholder in place of its projects', () => {
        expect(findEmptyItem().text()).toBe('No projects');
      });

      it('renders no extra selectable item', () => {
        expect(findItems()).toHaveLength(mockTopLevelGroups.length);
      });

      it('marks the placeholder as unselectable', () => {
        expect(findOptions().find(({ placeholder }) => placeholder)).toMatchObject({
          disabled: true,
        });
      });
    });

    describe('when more top-level groups are available', () => {
      const endCursor = 'groups-page-1';

      const respondWithTwoGroupPages = () =>
        jest
          .fn()
          .mockResolvedValueOnce(topLevelGroupsPage(mockTopLevelGroups, endCursor))
          .mockResolvedValueOnce(topLevelGroupsPage([mockUmbrellaCorp]));

      beforeEach(async () => {
        createWrapper({ topLevelGroupsHandler: respondWithTwoGroupPages() });
        await waitForPromises();
      });

      it('ends the list with a Load more row', () => {
        expect(findItemTexts()).toEqual([mockCapsuleCorp.name, mockAcme.name, 'Load more groups']);
        expect(findListLoadMore().props('nested')).toBe(false);
      });

      it('leaves the row unselectable, it carrying only the button', () => {
        expect(findOptions().at(-1)).toMatchObject({ disabled: true });
      });

      it('gives the row a value of its own', () => {
        const values = findOptions().map(({ value }) => value);

        expect(new Set(values).size).toBe(values.length);
      });

      describe('when it is clicked', () => {
        beforeEach(() => findListLoadMore().vm.$emit('load-more'));

        it('asks for the next page from where the last one ended', () => {
          expect(topLevelGroupsRequestHandler).toHaveBeenLastCalledWith({ after: endCursor });
        });

        it('sets the loading state on the button, not the listbox', () => {
          expect(findListLoadMore().props('loading')).toBe(true);
          expect(findListbox().props('loading')).toBe(false);
        });

        describe('once the page arrives', () => {
          beforeEach(() => waitForPromises());

          it('appends it to the groups already listed', () => {
            expect(findItemValues()).toEqual([
              ...mockTopLevelGroups.map(({ fullPath }) => fullPath),
              mockUmbrellaCorp.fullPath,
            ]);
          });

          it('drops the row, the last page having arrived', () => {
            expect(findLoadMoreItems()).toHaveLength(0);
          });
        });
      });

      describe('when the next page fails', () => {
        const error = new Error('oh no');

        beforeEach(async () => {
          createWrapper({
            topLevelGroupsHandler: jest
              .fn()
              .mockResolvedValueOnce(topLevelGroupsPage(mockTopLevelGroups, endCursor))
              .mockRejectedValueOnce(error),
          });
          await waitForPromises();
          findListLoadMore().vm.$emit('load-more');
          await waitForPromises();
        });

        it('emits error', () => {
          expect(wrapper.emitted('error')).toEqual([[error]]);
        });

        it('logs the error to sentry', () => {
          expect(sentryBrowserWrapper.captureException).toHaveBeenCalledWith(error);
        });

        it('keeps the groups already listed, and the row, so it can be asked for again', () => {
          expect(findItemTexts()).toEqual([
            mockCapsuleCorp.name,
            mockAcme.name,
            'Load more groups',
          ]);
          expect(findListLoadMore().props('loading')).toBe(false);
        });
      });
    });

    describe('when an expanded group has more projects available', () => {
      const endCursor = 'projects-page-1';

      const respondWithTwoProjectPages = () =>
        jest
          .fn()
          .mockResolvedValueOnce(subgroupProjectsPage(mockCapsuleProjects, endCursor))
          .mockResolvedValueOnce(subgroupProjectsPage([mockExtraCapsuleProject]));

      const projectNames = mockCapsuleProjects.map(({ name }) => name);

      beforeEach(async () => {
        createWrapper({ subgroupHandler: respondWithTwoProjectPages() });
        await waitForPromises();
        await toggleExpanded(mockCapsuleCorp);
        await waitForPromises();
      });

      it("ends the group's projects with a Load more row, indented alongside them", () => {
        expect(findItemTexts()).toEqual([
          mockCapsuleCorp.name,
          ...projectNames,
          `Load more projects in ${mockCapsuleCorp.name}`,
          mockAcme.name,
        ]);
        expect(findGroupLoadMore().props('nested')).toBe(true);
      });

      describe('when it is clicked', () => {
        beforeEach(() => findGroupLoadMore().vm.$emit('load-more'));

        it("asks for the next page of that group's projects", () => {
          expect(subgroupRequestHandler).toHaveBeenLastCalledWith({
            fullPath: mockCapsuleCorp.fullPath,
            after: endCursor,
          });
        });

        it('sets the loading state for the button, not the group', () => {
          expect(findGroupLoadMore().props('loading')).toBe(true);
          expect(findItemFor(mockCapsuleCorp).props('expanding')).toBe(false);
        });

        describe('once the page arrives', () => {
          beforeEach(() => waitForPromises());

          it('appends it beneath the projects already revealed', () => {
            expect(findItemValues()).toEqual([
              mockCapsuleCorp.fullPath,
              ...mockCapsuleProjects.map(({ fullPath }) => fullPath),
              mockExtraCapsuleProject.fullPath,
              mockAcme.fullPath,
            ]);
          });

          it('drops the row, the last page having arrived', () => {
            expect(findLoadMoreItems()).toHaveLength(0);
          });
        });
      });

      describe('when the next page fails', () => {
        const error = new Error('oh no');

        beforeEach(async () => {
          createWrapper({
            subgroupHandler: jest
              .fn()
              .mockResolvedValueOnce(subgroupProjectsPage(mockCapsuleProjects, endCursor))
              .mockRejectedValueOnce(error),
          });
          await waitForPromises();
          await toggleExpanded(mockCapsuleCorp);
          await waitForPromises();
          findGroupLoadMore().vm.$emit('load-more');
          await waitForPromises();
        });

        it('emits error', () => {
          expect(wrapper.emitted('error')).toEqual([[error]]);
        });

        it('keeps the projects already revealed, and the row, so it can be asked for again', () => {
          expect(findItemTexts()).toEqual([
            mockCapsuleCorp.name,
            ...projectNames,
            `Load more projects in ${mockCapsuleCorp.name}`,
            mockAcme.name,
          ]);
          expect(findGroupLoadMore().props('loading')).toBe(false);
        });
      });
    });

    describe("when the first page of a group's projects fails", () => {
      const error = new Error('oh no');

      beforeEach(async () => {
        createWrapper({ subgroupHandler: jest.fn().mockRejectedValue(error) });
        await waitForPromises();
        await toggleExpanded(mockCapsuleCorp);
        await waitForPromises();
      });

      it('emits error', () => {
        expect(wrapper.emitted('error')).toEqual([[error]]);
      });

      it('collapses the group, so expanding it again retries', async () => {
        expect(findItemFor(mockCapsuleCorp).props('expanded')).toBe(false);

        await toggleExpanded(mockCapsuleCorp);

        expect(subgroupRequestHandler).toHaveBeenCalledTimes(2);
      });
    });

    describe('when the user belongs to no groups', () => {
      beforeEach(async () => {
        createWrapper({ topLevelGroupsHandler: respondWithTopLevelGroups([]) });
        await waitForPromises();
      });

      it('renders no items', () => {
        expect(findItems()).toHaveLength(0);
      });
    });

    describe('when the query fails', () => {
      const error = new Error('oh no');

      beforeEach(async () => {
        createWrapper({ topLevelGroupsHandler: jest.fn().mockRejectedValue(error) });
        await waitForPromises();
      });

      it('emits error', () => {
        expect(wrapper.emitted('error')).toEqual([[error]]);
      });

      it('logs the error to sentry', () => {
        expect(sentryBrowserWrapper.captureException).toHaveBeenCalledWith(error);
      });
    });
  });

  describe('selecting more than one namespace', () => {
    beforeEach(async () => {
      createWrapper();
      await waitForPromises();
      await selectAll(mockCapsuleCorp, mockAcme);
    });

    it('keeps every pick', () => {
      expect(findSelectedNames()).toEqual([mockCapsuleCorp.name, mockAcme.name]);
    });

    it('counts them on the toggle rather than naming one', () => {
      expect(findListbox().props('toggleText')).toBe('2 items selected');
    });

    it('emits the whole selection, not just what changed', async () => {
      await hideListbox();

      expect(wrapper.emitted('change').at(-1)).toEqual([
        [asNamespace(mockCapsuleCorp), asNamespace(mockAcme)],
      ]);
    });

    it('counts them against the cap, in the footer and the header alike', () => {
      expect(findSlotsLeft().text()).toBe('18 of 20 slots left');
    });

    describe('when one of them is unticked', () => {
      beforeEach(() => toggleSelected(mockCapsuleCorp));

      it('leaves the other selected', () => {
        expect(findSelectedNames()).toEqual([mockAcme.name]);
      });

      it('names the one that is left', () => {
        expect(findListbox().props('toggleText')).toBe(mockAcme.name);
      });

      it('gives the slot back', () => {
        expect(findSlotsLeft().text()).toBe('19 of 20 slots left');
      });
    });

    // A group covers everything beneath it, so a project already picked there stops being a
    // pick of its own rather than counting twice against the cap.
    describe('when a group is picked over projects already selected beneath it', () => {
      beforeEach(async () => {
        createWrapper();
        await waitForPromises();
        await toggleExpanded(mockCapsuleCorp);
        await waitForPromises();

        await selectAll(mockCapsuleProjects[0], mockCapsuleCorp);
      });

      it('drops them, holding the group alone', async () => {
        await hideListbox();

        expect(wrapper.emitted('change').at(-1)).toEqual([[asNamespace(mockCapsuleCorp)]]);
      });

      it('leaves one slot spent, not two', () => {
        expect(findSlotsLeft().text()).toBe('19 of 20 slots left');
      });
    });
  });

  describe('the selected section', () => {
    beforeEach(async () => {
      createWrapper();
      await waitForPromises();
    });

    describe('once namespaces are picked', () => {
      beforeEach(() => selectAll(mockAcme, mockCapsuleCorp));

      it('shows separated sections for selected/unselected items', () => {
        expect(findSectionNames()).toEqual(['Selected', 'Groups and projects']);
      });

      it('pins the picks above the list, in the order they were picked', () => {
        expect(findItemTexts()).toEqual([
          mockAcme.name,
          mockCapsuleCorp.name,
          mockCapsuleCorp.name,
          mockAcme.name,
        ]);
        expect(findSelectedNames()).toEqual([mockAcme.name, mockCapsuleCorp.name]);
      });

      it('renders the pinned rows checked, under the names of the picks', () => {
        expect(
          findPinnedItems().map((item) => ({
            text: item.props('text'),
            selected: item.props('selected'),
          })),
        ).toEqual([
          { text: 'Acme Inc', selected: true },
          { text: 'Capsule Corp', selected: true },
        ]);
      });

      it('leaves the picks checked in place in the list below', () => {
        expect(findItemFor(mockAcme).props('selected')).toBe(true);
        expect(findItemFor(mockCapsuleCorp).props('selected')).toBe(true);
      });

      it('counts the pinned rows as selected alongside the rows below', () => {
        expect(findListbox().props('selected')).toEqual([
          ...findPinnedValues(),
          mockCapsuleCorp.fullPath,
          mockAcme.fullPath,
        ]);
      });

      describe('when a pick is unticked from its pinned row', () => {
        beforeEach(() => untickPinned(mockAcme.name));

        it('drops the pick', () => {
          expect(findSelectedNames()).toEqual([mockCapsuleCorp.name]);
        });

        it('leaves its row in the list below, unchecked', () => {
          expect(findListValues()).toEqual([mockCapsuleCorp.fullPath, mockAcme.fullPath]);
          expect(findItemFor(mockAcme).props('selected')).toBe(false);
        });
      });

      it('goes back to a flat list once the last pick is unticked', async () => {
        await selectAll(mockAcme, mockCapsuleCorp);

        expectFlatList();
      });
    });

    it('leaves a top-level pick without a parent, there being nothing above it', async () => {
      await toggleSelected(mockCapsuleCorp);

      const [pinned] = findPinnedItems();

      expect(pinned.props('parentName')).toBeNull();
    });

    describe('when a nested project is picked', () => {
      beforeEach(async () => {
        await toggleExpanded(mockCapsuleCorp);
        await waitForPromises();
        await toggleSelected(mockCapsuleProjects[1]);
      });

      it('names the group it sits in, the same way a nested row does', () => {
        const [pinned] = findPinnedItems();

        expect(pinned.props('parentName')).toBe('Research');
      });
    });

    // The pinned row only stands for the pick, so browsing what is under it stays in the list.
    it('keeps a pinned group closed, even while its row below is expanded', async () => {
      await toggleExpanded(mockCapsuleCorp);
      await waitForPromises();
      await toggleSelected(mockCapsuleCorp);

      const [pinned] = findPinnedItems();

      expect(pinned.props()).toMatchObject({
        expandable: false,
        expanded: false,
        expanding: false,
      });
      expect(findItemFor(mockCapsuleCorp).props('expanded')).toBe(true);
    });
  });

  describe('while the listbox is open', () => {
    beforeEach(async () => {
      createWrapper();
      await waitForPromises();
    });

    it('holds picks back rather than emitting each one', async () => {
      await selectAll(mockCapsuleCorp, mockAcme);

      expect(findSelectedNames()).toEqual([mockCapsuleCorp.name, mockAcme.name]);
      expect(wrapper.emitted('change')).toBeUndefined();
    });

    it('emits the whole selection once when it closes', async () => {
      await selectAll(mockCapsuleCorp, mockAcme);
      await hideListbox();

      expect(wrapper.emitted('change')).toEqual([
        [[asNamespace(mockCapsuleCorp), asNamespace(mockAcme)]],
      ]);
    });

    it('emits nothing on close when the picks cancel out', async () => {
      await selectAll(mockCapsuleCorp, mockCapsuleCorp);
      await hideListbox();

      expect(wrapper.emitted('change')).toBeUndefined();
    });

    it('emits nothing when it closes again without further changes', async () => {
      await toggleSelected(mockCapsuleCorp);
      await hideListbox();
      await hideListbox();

      expect(wrapper.emitted('change')).toHaveLength(1);
    });

    it('emits an emptied selection when everything is unticked', async () => {
      await toggleSelected(mockCapsuleCorp);
      await hideListbox();
      await toggleSelected(mockCapsuleCorp);
      await hideListbox();

      expect(wrapper.emitted('change').at(-1)).toEqual([[]]);
    });
  });

  describe('when the selection is full', () => {
    // One more than the cap, so there is always a row left that cannot be added.
    const manyGroups = Array.from({ length: 21 }, (_, index) =>
      mockTopLevelGroup({ id: 200 + index, name: `Group ${index}`, path: `group-${index}` }),
    );
    const [spareGroup] = manyGroups.slice(-1);

    beforeEach(async () => {
      createWrapper({ topLevelGroupsHandler: respondWithTopLevelGroups(manyGroups) });
      await waitForPromises();
      await selectAll(...manyGroups.slice(0, 20));
    });

    it('holds the cap GLQL can compile', () => {
      expect(findSelectedNames()).toHaveLength(20);
      expect(findSlotsLeft().text()).toBe('0 of 20 slots left');
    });

    it('leaves the rows that would grow it unselectable', () => {
      expect(findItemFor(spareGroup).props('disabled')).toBe(true);
    });

    it('refuses the pick even if the row is clicked anyway', async () => {
      await toggleSelected(spareGroup);

      expect(findSelectedNames()).toHaveLength(20);
      expect(findSelectedNames()).not.toContain(spareGroup.name);
    });

    it('keeps the picks themselves clickable, so the selection can be freed up', async () => {
      expect(findItemFor(manyGroups[0]).props('disabled')).toBe(false);

      await toggleSelected(manyGroups[0]);

      expect(findSlotsLeft().text()).toBe('1 of 20 slots left');
      expect(findItemFor(spareGroup).props('disabled')).toBe(false);
    });
  });

  describe('when multi-select is off', () => {
    beforeEach(async () => {
      createWrapper({ props: { multiSelect: false } });
      await waitForPromises();
    });

    it('holds one pick at a time, a second replacing the first', async () => {
      await selectAll(mockCapsuleCorp, mockAcme);

      expect(findSelectedNames()).toEqual([mockAcme.name]);
      expect(wrapper.emitted('change').at(-1)).toEqual([[asNamespace(mockAcme)]]);
    });

    it('emits each pick straight away, without waiting for the listbox to close', async () => {
      await toggleSelected(mockCapsuleCorp);

      expect(wrapper.emitted('change')).toEqual([[[asNamespace(mockCapsuleCorp)]]]);
    });

    it('names the pick on the toggle', async () => {
      await toggleSelected(mockCapsuleCorp);

      expect(findListbox().props('toggleText')).toBe(mockCapsuleCorp.name);
    });

    it('keeps every row clickable once a pick is made', async () => {
      await toggleSelected(mockCapsuleCorp);

      expect(findItemFor(mockAcme).props('disabled')).toBe(false);
    });

    it('still clears the selection when the pick is unticked', async () => {
      await toggleSelected(mockCapsuleCorp);
      await toggleSelected(mockCapsuleCorp);

      expectEmptyState();
    });

    it('does not show the slot count', () => {
      expect(findSlotsLeft().exists()).toBe(false);
    });

    describe('when the URL names several paths', () => {
      beforeEach(async () => {
        createWrapper({
          props: {
            multiSelect: false,
            initialPaths: [mockCapsuleCorp.fullPath, mockAcme.fullPath],
          },
          scopeNamespaceHandler: respondWithScopeNamespaces({
            [mockCapsuleCorp.fullPath]: mockCapsuleCorp,
            [mockAcme.fullPath]: mockAcme,
          }),
        });
        await waitForPromises();
      });

      it('looks up only the one it can hold', () => {
        expect(scopeNamespaceRequestHandler).toHaveBeenCalledTimes(1);
      });

      it('restores that one alone', () => {
        expect(findSelectedNames()).toEqual([mockCapsuleCorp.name]);
      });
    });
  });

  describe('when Done is clicked', () => {
    beforeEach(async () => {
      createWrapper();
      await waitForPromises();
    });

    it('closes the listbox', () => {
      findDoneButton().vm.$emit('click');

      expect(closeListbox).toHaveBeenCalled();
    });
  });

  describe('searching', () => {
    describe('across everything the user can reach', () => {
      beforeEach(async () => {
        createWrapper();
        await waitForPromises();
        await search('design');
      });

      it('searches on the trimmed term', async () => {
        expect(globalSearchRequestHandler).toHaveBeenCalledWith({ search: 'design' });

        await search('  design  ');

        expect(globalSearchRequestHandler).toHaveBeenLastCalledWith({ search: 'design' });
      });

      it('treats whitespace alone as no search at all', async () => {
        globalSearchRequestHandler.mockClear();
        await search('   ');

        expect(globalSearchRequestHandler).not.toHaveBeenCalled();
        expect(findOptions().map(({ value }) => value)).toEqual(
          mockTopLevelGroups.map(({ fullPath }) => fullPath),
        );
      });

      it('replaces the browse view with one flat, headerless list', () => {
        expect(findSections().every(({ options }) => options === undefined)).toBe(true);
        expect(findOptions().map(({ value }) => value)).toEqual([
          mockDeepSubgroup.fullPath,
          mockDeepProject.fullPath,
        ]);
      });

      it('announces how many results the search found', () => {
        expect(findSearchSummary().text()).toBe('2 results');
      });

      it('reaches a subgroup too deep for browsing to reveal', () => {
        expect(findItemFor(mockDeepSubgroup).exists()).toBe(true);
      });

      it('names each parent, since a result can come from anywhere', () => {
        expect(findItemFor(mockDeepSubgroup).props('parentName')).toBe(mockFrontend.name);
        expect(findItemFor(mockDeepProject).props('parentName')).toBe(mockDeepSubgroup.name);
      });

      it('distinguishes a group from a project by icon rather than by heading', () => {
        expect(findItemFor(mockDeepSubgroup).props('itemType')).toBe(SCOPE_PICKER_ITEM_TYPE_GROUP);
        expect(findItemFor(mockDeepProject).props('itemType')).toBe(SCOPE_PICKER_ITEM_TYPE_PROJECT);
      });

      it('offers no chevrons, results being flat however deep they sit', () => {
        expect(findItems().wrappers.every((item) => item.props('expandable'))).toBe(false);
      });

      it('selects a result the same way a browsed row is selected', async () => {
        await toggleSelected(mockDeepProject);
        await hideListbox();

        expect(wrapper.emitted('change').at(-1)).toEqual([[asNamespace(mockDeepProject)]]);
      });

      it('keeps the toggle text once the search is cleared', async () => {
        await toggleSelected(mockDeepProject);
        await search('');

        expect(findListbox().props('toggleText')).toBe(mockDeepProject.name);
      });

      it('restores the browse view when the search is cleared', async () => {
        await search('');

        expect(findOptions().map(({ value }) => value)).toEqual([
          mockCapsuleCorp.fullPath,
          mockAcme.fullPath,
        ]);
      });

      // The listbox owns its input's value and never clears it, so clearing ours on close would
      // only leave the box reading "design" over an unfiltered browse tree.
      it('keeps the search when the listbox closes, so the box and the rows still agree', async () => {
        await findListbox().vm.$emit('hidden');

        expect(findOptions().map(({ value }) => value)).toEqual([
          mockDeepSubgroup.fullPath,
          mockDeepProject.fullPath,
        ]);
      });
    });

    // Apollo replaces the results wholesale, so a second search is the only thing that takes the
    // first one's rows away. Clearing the search leaves them cached, which is why it never showed
    // this up.
    describe('when a second search replaces the results the selection came from', () => {
      beforeEach(async () => {
        createWrapper({
          globalSearchHandler: jest
            .fn()
            .mockResolvedValueOnce(searchResponse())
            .mockResolvedValue(searchResponse({ groups: [], projects: [mockUnrelatedProject] })),
        });
        await waitForPromises();

        await search('pajamas');
        await toggleSelected(mockDeepProject);
        await hideListbox();
        await search('charts');
      });

      it('goes on naming the selection the consumer still holds', () => {
        expect(findListbox().props('toggleText')).toBe(mockDeepProject.name);
      });

      it('emits no change, nothing about the selection having been touched', () => {
        expect(wrapper.emitted('change')).toEqual([[[asNamespace(mockDeepProject)]]]);
      });

      // Otherwise the listbox takes the toggle for an empty picker and greys the name it shows.
      it('holds the selection pinned above the results, none of which carry it', () => {
        expect(findSelectedNames()).toEqual([mockDeepProject.name]);
        expect(findListValues()).toEqual([mockUnrelatedProject.fullPath]);
        expect(findListbox().props('selected')).toEqual(findPinnedValues());
      });

      it('still names it once the search is cleared and browsing resumes', async () => {
        await search('');

        expect(findListbox().props('toggleText')).toBe(mockDeepProject.name);
      });
    });

    describe('while a search is in flight', () => {
      beforeEach(async () => {
        createWrapper({ globalSearchHandler: jest.fn().mockReturnValue(new Promise(() => {})) });
        await waitForPromises();
        await search('design');
      });

      // The listbox's own spinners would hide every row, pinned picks included.
      it('reports it in a row of its own, leaving the listbox spinners alone', () => {
        expect(findEmptyItem().text()).toBe('Searching');
        expect(findEmptyItem().findComponent(GlLoadingIcon).exists()).toBe(true);
        expect(findListbox().props('searching')).toBe(false);
        expect(findListbox().props('loading')).toBe(false);
      });

      it('announces it to screen readers while focus stays in the search box', () => {
        expect(findSearchSummary().text()).toBe('Searching');
      });
    });

    describe('when a search returns nothing', () => {
      beforeEach(async () => {
        createWrapper({
          globalSearchHandler: respondWithGlobalSearch({ groups: [], projects: [] }),
        });
        await waitForPromises();
        await search('nothing');
      });

      it('says so in a row of its own', () => {
        expect(findItems()).toHaveLength(0);
        expect(findEmptyItem().text()).toBe('No groups or projects found');
      });

      // The listbox would count the status row and announce "1 result".
      it('announces that nothing was found rather than counting the status row', () => {
        expect(findSearchSummary().text()).toBe('No groups or projects found');
      });
    });

    describe('with a pick pinned above the results', () => {
      const pickThenSearch = async (globalSearchHandler) => {
        createWrapper({ globalSearchHandler });
        await waitForPromises();
        await toggleSelected(mockAcme);
        await search('design');
      };

      it('keeps the pick on screen above a searching row while the search is in flight', async () => {
        await pickThenSearch(jest.fn().mockReturnValue(new Promise(() => {})));

        expect(findSelectedNames()).toEqual([mockAcme.name]);
        expect(findListValues()).toHaveLength(1);
        expect(findEmptyItem().text()).toBe('Searching');
      });

      it('lists the results below the pick once they arrive', async () => {
        await pickThenSearch(respondWithGlobalSearch());

        expect(findSelectedNames()).toEqual([mockAcme.name]);
        expect(findListValues()).toEqual([mockDeepSubgroup.fullPath, mockDeepProject.fullPath]);
        expect(findEmptyItem().exists()).toBe(false);
        expect(findSearchSummary().text()).toBe('2 results');
      });

      it('says there is nothing below the pick when the search returns nothing', async () => {
        await pickThenSearch(respondWithGlobalSearch({ groups: [], projects: [] }));

        expect(findSelectedNames()).toEqual([mockAcme.name]);
        expect(findListValues()).toHaveLength(1);
        expect(findEmptyItem().text()).toBe('No groups or projects found');
        expect(findSearchSummary().text()).toBe('No groups or projects found');
      });
    });

    describe('when a search fails', () => {
      const error = new Error('oh no');

      beforeEach(async () => {
        createWrapper({ globalSearchHandler: jest.fn().mockRejectedValue(error) });
        await waitForPromises();
        await search('design');
      });

      // Apollo never runs update on a rejection, so anything keying off "results have not
      // arrived yet" would stay true forever and leave the listbox spinning with no way out.
      it('stops searching, rather than spinning on a result that will never arrive', () => {
        expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(false);
      });

      it('emits error', () => {
        expect(wrapper.emitted('error')).toEqual([[error]]);
      });

      it('logs the error to sentry', () => {
        expect(sentryBrowserWrapper.captureException).toHaveBeenCalledWith(error);
      });
    });
  });

  describe('the initial paths, as the `scope` URL param supplies', () => {
    const initialPath = mockFrontend.fullPath;
    const initialPaths = [initialPath];

    const respondWithGroup = (group) => ({
      data: { group, projects: { __typename: 'ProjectConnection', nodes: [] } },
    });

    // Leaves the lookup outstanding once the browse queries have settled, so the two can be
    // told apart.
    const deferLookup = () => {
      let resolveLookup;
      const handler = jest.fn(
        () =>
          new Promise((resolve) => {
            resolveLookup = resolve;
          }),
      );

      return { handler, resolve: (value) => resolveLookup(value) };
    };

    it('does not look anything up when no paths are given', async () => {
      createWrapper();
      await waitForPromises();

      expect(scopeNamespaceRequestHandler).not.toHaveBeenCalled();
      expect(findListbox().props('toggleText')).toBe('Select a group or project');
    });

    // A path alone does not say which kind it is, so both sides go in the same request.
    it('looks each path up as both a group and a project', () => {
      createWrapper({ props: { initialPaths: [mockCapsuleCorp.fullPath, initialPath] } });

      expect(scopeNamespaceRequestHandler).toHaveBeenCalledTimes(2);
      expect(scopeNamespaceRequestHandler).toHaveBeenCalledWith({
        fullPath: mockCapsuleCorp.fullPath,
        fullPaths: [mockCapsuleCorp.fullPath],
      });
      expect(scopeNamespaceRequestHandler).toHaveBeenCalledWith({
        fullPath: initialPath,
        fullPaths: [initialPath],
      });
    });

    // Nothing can be picked until the lookup lands, so a pick can never race it.
    it('holds the list in its loading state until the lookup lands', async () => {
      const lookup = deferLookup();
      createWrapper({ props: { initialPaths }, scopeNamespaceHandler: lookup.handler });
      await waitForPromises();

      expect(findListbox().props('loading')).toBe(true);
      expect(wrapper.emitted('ready')).toBeUndefined();

      lookup.resolve(respondWithGroup(mockFrontend));
      await waitForPromises();

      expect(findListbox().props('loading')).toBe(false);
      expect(findListbox().props('toggleText')).toBe(mockFrontend.name);
    });

    it('emits ready once, after the change the lookup caused', async () => {
      const { events, listeners } = recordEvents();
      createWrapper({
        props: { initialPaths: [mockCapsuleCorp.fullPath] },
        scopeNamespaceHandler: respondWithScopeNamespace({ group: mockCapsuleCorp }),
        listeners,
      });
      await waitForPromises();

      expect(events).toEqual(['change', 'ready']);
    });

    describe('when a path is a group', () => {
      beforeEach(async () => {
        createWrapper({
          props: { initialPaths: [mockCapsuleCorp.fullPath] },
          scopeNamespaceHandler: respondWithScopeNamespace({ group: mockCapsuleCorp }),
        });
        await waitForPromises();
      });

      it('names it on the toggle', () => {
        expect(findListbox().props('toggleText')).toBe(mockCapsuleCorp.name);
      });

      it('marks its row selected', () => {
        expect(findSelectedNames()).toEqual([mockCapsuleCorp.name]);
      });

      // Emitted like a click, so the page applies it as an ordinary filter change.
      it('emits it as a change', () => {
        expect(wrapper.emitted('change')).toEqual([[[asNamespace(mockCapsuleCorp)]]]);
      });
    });

    describe('when a path is a project', () => {
      beforeEach(async () => {
        createWrapper({
          props: { initialPaths: [mockScopeProject.fullPath] },
          scopeNamespaceHandler: respondWithScopeNamespace({ projects: [mockScopeProject] }),
        });
        await waitForPromises();
      });

      it('names it on the toggle', () => {
        expect(findListbox().props('toggleText')).toBe(mockScopeProject.name);
      });

      it('emits it as a change, typed as a project', () => {
        expect(wrapper.emitted('change')).toEqual([[[asNamespace(mockScopeProject)]]]);
      });

      // Browsing has not reached it, so the pinned row is the only one standing for it.
      it('allows a non-loaded item to be selected by default', () => {
        expect(findSelectedNames()).toEqual([mockScopeProject.name]);
        expect(findListValues()).not.toContain(mockScopeProject.fullPath);
      });
    });

    describe('when the paths name a mix of groups and projects', () => {
      const paths = [mockScopeProject.fullPath, mockCapsuleCorp.fullPath, mockAcme.fullPath];

      beforeEach(async () => {
        createWrapper({
          props: { initialPaths: paths },
          scopeNamespaceHandler: respondWithScopeNamespaces({
            [mockScopeProject.fullPath]: mockScopeProject,
            [mockCapsuleCorp.fullPath]: mockCapsuleCorp,
            [mockAcme.fullPath]: mockAcme,
          }),
        });
        await waitForPromises();
      });

      it('selects every one of them', () => {
        expect(findSelectedNames()).toEqual([
          mockScopeProject.name,
          mockCapsuleCorp.name,
          mockAcme.name,
        ]);
      });

      it('counts them on the toggle rather than naming one', () => {
        expect(findListbox().props('toggleText')).toBe('3 items selected');
      });

      it('emits them as a single change', () => {
        expect(wrapper.emitted('change')).toEqual([
          [[asNamespace(mockScopeProject), asNamespace(mockCapsuleCorp), asNamespace(mockAcme)]],
        ]);
      });
    });

    describe('when one path resolves to nothing', () => {
      beforeEach(async () => {
        createWrapper({
          props: { initialPaths: [mockCapsuleCorp.fullPath, 'gone/missing'] },
          scopeNamespaceHandler: respondWithScopeNamespaces({
            [mockCapsuleCorp.fullPath]: mockCapsuleCorp,
          }),
        });
        await waitForPromises();
      });

      it('drops it and keeps the rest', () => {
        expect(findSelectedNames()).toEqual([mockCapsuleCorp.name]);
      });

      it('emits the selection it could resolve', () => {
        expect(wrapper.emitted('change')).toEqual([[[asNamespace(mockCapsuleCorp)]]]);
      });

      it('emits no error', () => {
        expect(wrapper.emitted('error')).toBeUndefined();
      });
    });

    describe('when one path errors while the rest resolve', () => {
      const error = new Error('one bad path');

      beforeEach(async () => {
        createWrapper({
          props: { initialPaths: [mockCapsuleCorp.fullPath, mockAcme.fullPath] },
          scopeNamespaceHandler: jest.fn().mockImplementation(({ fullPath }) =>
            fullPath === mockAcme.fullPath
              ? Promise.reject(error)
              : Promise.resolve({
                  data: {
                    group: mockCapsuleCorp,
                    projects: { __typename: 'ProjectConnection', nodes: [] },
                  },
                }),
          ),
        });
        await waitForPromises();
      });

      it('restores the ones that resolved', () => {
        expect(findSelectedNames()).toEqual([mockCapsuleCorp.name]);
        expect(wrapper.emitted('change')).toEqual([[[asNamespace(mockCapsuleCorp)]]]);
      });

      it('logs the failure to sentry', () => {
        expect(sentryBrowserWrapper.captureException).toHaveBeenCalledWith(error);
      });

      it('tells the page nothing, the selection still being usable', () => {
        expect(wrapper.emitted('error')).toBeUndefined();
      });
    });

    describe('when the same path is named twice', () => {
      beforeEach(async () => {
        createWrapper({
          props: { initialPaths: [mockCapsuleCorp.fullPath, mockCapsuleCorp.fullPath] },
          scopeNamespaceHandler: respondWithScopeNamespaces({
            [mockCapsuleCorp.fullPath]: mockCapsuleCorp,
          }),
        });
        await waitForPromises();
      });

      it('looks it up once', () => {
        expect(scopeNamespaceRequestHandler).toHaveBeenCalledTimes(1);
      });

      it('spends one slot on it, not two', () => {
        expect(findSelectedNames()).toEqual([mockCapsuleCorp.name]);
        expect(findSlotsLeft().text()).toBe('19 of 20 slots left');
      });
    });

    describe('when a path is a descendant of another path', () => {
      beforeEach(async () => {
        createWrapper({
          props: {
            initialPaths: [mockCapsuleCorp.fullPath, mockCapsuleProjects[0].fullPath],
          },
          scopeNamespaceHandler: respondWithScopeNamespaces({
            [mockCapsuleCorp.fullPath]: mockCapsuleCorp,
            [mockCapsuleProjects[0].fullPath]: mockCapsuleProjects[0],
          }),
        });
        await waitForPromises();
      });

      it('never looks the child path up', () => {
        expect(scopeNamespaceRequestHandler).toHaveBeenCalledTimes(1);
        expect(scopeNamespaceRequestHandler).toHaveBeenCalledWith({
          fullPath: mockCapsuleCorp.fullPath,
          fullPaths: [mockCapsuleCorp.fullPath],
        });
      });

      it('holds the covering group alone', () => {
        expect(findSelectedNames()).toEqual([mockCapsuleCorp.name]);
        expect(findSlotsLeft().text()).toBe('19 of 20 slots left');
      });
    });

    describe('when the paths run past what the picker holds', () => {
      const paths = Array.from({ length: 25 }, (_, index) => `group-${index}`);

      beforeEach(async () => {
        createWrapper({ props: { initialPaths: paths } });
        await waitForPromises();
      });

      it('only looks up the first 20 items', () => {
        expect(scopeNamespaceRequestHandler).toHaveBeenCalledTimes(20);
        expect(scopeNamespaceRequestHandler).not.toHaveBeenCalledWith({
          fullPath: 'group-20',
          fullPaths: ['group-20'],
        });
      });
    });

    // Renamed, deleted, or not visible to this user.
    describe('when no path resolves', () => {
      beforeEach(async () => {
        createWrapper({
          props: { initialPaths },
          scopeNamespaceHandler: respondWithScopeNamespace(),
        });
        await waitForPromises();
      });

      it('leaves the picker empty rather than naming something whose panels cannot load', () => {
        expectEmptyState();
      });

      it('emits no change', () => {
        expect(wrapper.emitted('change')).toBeUndefined();
      });

      it('emits ready', () => {
        expectReadyOnce();
      });
    });

    describe('when the lookup fails', () => {
      const error = new Error('nope');

      beforeEach(async () => {
        createWrapper({
          props: { initialPaths },
          scopeNamespaceHandler: jest.fn().mockRejectedValue(error),
        });
        await waitForPromises();
      });

      it('emits error', () => {
        expect(wrapper.emitted('error')).toEqual([[error]]);
      });

      it('logs the error to sentry', () => {
        expect(sentryBrowserWrapper.captureException).toHaveBeenCalledWith(error);
      });

      it('leaves the picker empty', () => {
        expect(findSelectedNames()).toEqual([]);
      });

      it('emits ready', () => {
        expectReadyOnce();
      });
    });

    // The page hands its current selection back down through this prop, so it changes on every
    // pick, not just the ones that came from the URL.
    describe('when the page echoes a pick back through the prop', () => {
      beforeEach(async () => {
        createWrapper();
        await waitForPromises();

        await toggleSelected(mockCapsuleCorp);
        await wrapper.setProps({ initialPaths: [mockCapsuleCorp.fullPath] });
      });

      it('looks nothing up, the click having already resolved the namespace', () => {
        expect(scopeNamespaceRequestHandler).not.toHaveBeenCalled();
      });

      it('keeps the pick', () => {
        expect(findSelectedNames()).toEqual([mockCapsuleCorp.name]);
      });
    });
  });

  describe('a default derived from the most frecent group', () => {
    const asFrecentGroup = ({ id, name, fullName, fullPath, userPermissions }) => ({
      __typename: TYPENAME_GROUP,
      id,
      name,
      fullName,
      fullPath,
      userPermissions,
    });

    const mockFrecentGroups = [asFrecentGroup(mockAcme), asFrecentGroup(mockCapsuleCorp)];
    const error = new Error('no such luck');
    const rejecting = () => jest.fn().mockRejectedValue(error);

    // Leaves the frecent lookup outstanding once the browse queries have settled.
    const deferFrecentGroups = () => {
      let resolveLookup;
      const handler = jest.fn(
        () =>
          new Promise((resolve) => {
            resolveLookup = resolve;
          }),
      );

      return { handler, resolve: (value) => resolveLookup(value) };
    };

    describe('when the load names no scope', () => {
      beforeEach(async () => {
        createWrapper({
          frecentGroupsHandler: respondWithFrecentGroups(mockFrecentGroups),
          organizationGroupHandler: respondWithOrganizationGroup([asFrecentGroup(mockAcme)]),
        });
        await waitForPromises();
      });

      it('asks for the frecent groups', () => {
        expect(frecentGroupsRequestHandler).toHaveBeenCalled();
      });

      it('validates that the most frecentGroup is in the organization', () => {
        expect(organizationGroupRequestHandler).toHaveBeenCalledWith({ ids: [mockAcme.id] });
      });

      it('names the most frecent group on the toggle', () => {
        expect(findListbox().props('toggleText')).toBe(mockAcme.name);
      });

      it('ticks its row alone, the rest of the list being no more than visited', () => {
        expect(findSelectedNames()).toEqual([mockAcme.name]);
      });

      it('emits it as a change', () => {
        expect(wrapper.emitted('change')).toEqual([[[asNamespace(mockAcme)]]]);
      });
    });

    it('emits ready once, after the change the default caused', async () => {
      const { events, listeners } = recordEvents();
      createWrapper({
        frecentGroupsHandler: respondWithFrecentGroups(mockFrecentGroups),
        organizationGroupHandler: respondWithOrganizationGroup([asFrecentGroup(mockAcme)]),
        listeners,
      });
      await waitForPromises();

      expect(events).toEqual(['change', 'ready']);
    });

    describe('when the `scope` URL param already names one', () => {
      beforeEach(async () => {
        createWrapper({
          props: { initialPaths: [mockCapsuleCorp.fullPath] },
          scopeNamespaceHandler: respondWithScopeNamespace({ group: mockCapsuleCorp }),
          frecentGroupsHandler: respondWithFrecentGroups(mockFrecentGroups),
        });
        await waitForPromises();
      });

      it('does not send a request for the frecent group', () => {
        expect(frecentGroupsRequestHandler).not.toHaveBeenCalled();
        expect(organizationGroupRequestHandler).not.toHaveBeenCalled();
      });

      it('keeps what the param named', () => {
        expect(findSelectedNames()).toEqual([mockCapsuleCorp.name]);
      });
    });

    describe('when the user has visited no groups', () => {
      beforeEach(async () => {
        createWrapper({ frecentGroupsHandler: respondWithFrecentGroups([]) });
        await waitForPromises();
      });

      it('has nothing to check against the organization', () => {
        expect(organizationGroupRequestHandler).not.toHaveBeenCalled();
      });

      it('leaves the picker empty, for the page to show its empty state', () => {
        expectEmptyState();
      });

      it('emits no change', () => {
        expect(wrapper.emitted('change')).toBeUndefined();
      });

      it('emits ready', () => {
        expectReadyOnce();
      });
    });

    describe('when the page organization does not hold the most frecent group', () => {
      beforeEach(async () => {
        createWrapper({
          frecentGroupsHandler: respondWithFrecentGroups(mockFrecentGroups),
          organizationGroupHandler: respondWithOrganizationGroup([]),
        });
        await waitForPromises();
      });

      it('leaves the picker empty rather than falling to the next frecent group', () => {
        expectEmptyState();
      });

      it('emits no change', () => {
        expect(wrapper.emitted('change')).toBeUndefined();
      });

      it('emits ready', () => {
        expectReadyOnce();
      });
    });

    describe('when the user clears the derived default', () => {
      beforeEach(async () => {
        createWrapper({
          frecentGroupsHandler: respondWithFrecentGroups(mockFrecentGroups),
          organizationGroupHandler: respondWithOrganizationGroup([asFrecentGroup(mockAcme)]),
        });
        await waitForPromises();

        await toggleSelected(mockAcme);
      });

      it('stays empty rather than deriving the default again', () => {
        expectEmptyState();
        expect(frecentGroupsRequestHandler).toHaveBeenCalledTimes(1);
        expect(organizationGroupRequestHandler).toHaveBeenCalledTimes(1);
      });

      it('emits the cleared selection', async () => {
        await hideListbox();

        expect(wrapper.emitted('change')).toEqual([[[asNamespace(mockAcme)]], [[]]]);
      });
    });

    it('stays in the loading state until the initial scope is ready', async () => {
      const lookup = deferFrecentGroups();
      createWrapper({
        frecentGroupsHandler: lookup.handler,
        organizationGroupHandler: respondWithOrganizationGroup([asFrecentGroup(mockAcme)]),
      });
      await waitForPromises();

      expect(findListbox().props('loading')).toBe(true);
      expect(wrapper.emitted('ready')).toBeUndefined();

      lookup.resolve({ data: { frecentGroups: mockFrecentGroups } });
      await waitForPromises();

      expect(findListbox().props('loading')).toBe(false);
      expect(findListbox().props('toggleText')).toBe(mockAcme.name);
    });

    describe('when the frecent groups query fails', () => {
      beforeEach(async () => {
        createWrapper({ frecentGroupsHandler: rejecting() });
        await waitForPromises();
      });

      it('logs the error to sentry', () => {
        expect(sentryBrowserWrapper.captureException).toHaveBeenCalledWith(error);
      });

      it('leaves the picker empty', () => {
        expectEmptyState();
      });

      it('emits ready', () => {
        expectReadyOnce();
      });
    });

    describe('when the organization check fails', () => {
      beforeEach(async () => {
        createWrapper({
          frecentGroupsHandler: respondWithFrecentGroups(mockFrecentGroups),
          organizationGroupHandler: rejecting(),
        });
        await waitForPromises();
      });

      it('logs the error to sentry', () => {
        expect(sentryBrowserWrapper.captureException).toHaveBeenCalledWith(error);
      });

      it('leaves the picker empty', () => {
        expectEmptyState();
      });

      it('emits ready', () => {
        expectReadyOnce();
      });
    });
  });

  describe('required permissions', () => {
    const requirePermissions = ['readProAiAnalytics'];

    const lockedGroup = { ...mockCapsuleCorp, userPermissions: groupPermissions(false) };
    // A backend that predates the field returns it as null.
    const unknownGroup = { ...mockAcme, userPermissions: groupPermissions(null) };
    const [openProject] = mockCapsuleProjects;
    const lockedProject = {
      ...mockCapsuleProjects[1],
      userPermissions: projectPermissions(false),
    };

    const createWrapperWithMixedPermissions = (props = {}) =>
      createWrapper({
        topLevelGroupsHandler: respondWithTopLevelGroups([lockedGroup, unknownGroup]),
        subgroupHandler: respondWithSubgroupProjects([openProject, lockedProject]),
        props,
      });

    describe('when the dashboard requires none', () => {
      beforeEach(async () => {
        createWrapperWithMixedPermissions();
        await waitForPromises();
      });

      it('locks nothing, whatever the namespace grants', () => {
        expect(findItemFor(lockedGroup).props()).toMatchObject({
          disabled: false,
          restricted: false,
        });
      });
    });

    describe('when the dashboard requires one and the group tree is browsed', () => {
      beforeEach(async () => {
        createWrapperWithMixedPermissions({ requirePermissions });
        await waitForPromises();
      });

      it('locks a group that denies one', () => {
        expect(findItemFor(lockedGroup).props()).toMatchObject({
          disabled: true,
          restricted: true,
        });
      });

      it('still lets a locked group expand, so the projects beneath it stay reachable', () => {
        expect(findItemFor(lockedGroup).props('expandable')).toBe(true);
      });

      it('leaves a group whose permission is unknown selectable', () => {
        expect(findItemFor(unknownGroup).props()).toMatchObject({
          disabled: false,
          restricted: false,
        });
      });

      describe('once a locked group is expanded', () => {
        beforeEach(async () => {
          await toggleExpanded(lockedGroup);
          await waitForPromises();
        });

        it('leaves a project that grants it selectable', () => {
          expect(findItemFor(openProject).props()).toMatchObject({
            disabled: false,
            restricted: false,
          });
        });

        it('locks a project that denies it', () => {
          expect(findItemFor(lockedProject).props()).toMatchObject({
            disabled: true,
            restricted: true,
          });
        });
      });
    });

    describe('when searching', () => {
      const lockedResult = { ...mockDeepSubgroup, userPermissions: groupPermissions(false) };

      beforeEach(async () => {
        createWrapper({
          globalSearchHandler: respondWithGlobalSearch({
            groups: [lockedResult],
            projects: [mockDeepProject],
          }),
          props: { requirePermissions },
        });
        await waitForPromises();
        await search('design');
      });

      it('locks a result that denies one', () => {
        expect(findItemFor(lockedResult).props()).toMatchObject({
          disabled: true,
          restricted: true,
        });
      });

      it('leaves a result that grants them selectable', () => {
        expect(findItemFor(mockDeepProject).props()).toMatchObject({
          disabled: false,
          restricted: false,
        });
      });
    });

    describe('when the `scope` URL param names a namespace that denies one', () => {
      beforeEach(async () => {
        createWrapper({
          scopeNamespaceHandler: respondWithScopeNamespace({ group: lockedGroup }),
          props: { requirePermissions, initialPaths: [lockedGroup.fullPath] },
        });
        await waitForPromises();
      });

      it('drops it rather than selecting it', () => {
        expectEmptyState();
        expect(wrapper.emitted('change')).toBeUndefined();
      });

      it('emits no error, nothing having failed', () => {
        expect(wrapper.emitted('error')).toBeUndefined();
      });
    });

    describe('when the `scope` URL param names one namespace that grants them and one that does not', () => {
      beforeEach(async () => {
        createWrapper({
          scopeNamespaceHandler: respondWithScopeNamespaces({
            [openProject.fullPath]: openProject,
            [lockedProject.fullPath]: lockedProject,
          }),
          props: {
            requirePermissions,
            multiSelect: true,
            initialPaths: [openProject.fullPath, lockedProject.fullPath],
          },
        });
        await waitForPromises();
      });

      it('restores only the one that grants them', () => {
        expect(findSelectedNames()).toEqual([openProject.name]);
        expect(wrapper.emitted('change')).toEqual([[[asNamespace(openProject)]]]);
      });
    });

    describe('when the `scope` URL param names a namespace whose permission is unknown', () => {
      beforeEach(async () => {
        createWrapper({
          scopeNamespaceHandler: respondWithScopeNamespace({ group: unknownGroup }),
          props: { requirePermissions, initialPaths: [unknownGroup.fullPath] },
        });
        await waitForPromises();
      });

      it('restores it', () => {
        expect(findSelectedNames()).toEqual([unknownGroup.name]);
        expect(wrapper.emitted('change')).toEqual([[[asNamespace(unknownGroup)]]]);
      });
    });

    describe('when the most frecent group denies one', () => {
      beforeEach(async () => {
        createWrapper({
          frecentGroupsHandler: respondWithFrecentGroups([mockAcme]),
          organizationGroupHandler: respondWithOrganizationGroup([
            { ...mockAcme, userPermissions: groupPermissions(false) },
          ]),
          props: { requirePermissions },
        });
        await waitForPromises();
      });

      it('does not derive a default from it', () => {
        expectEmptyState();
        expect(wrapper.emitted('change')).toBeUndefined();
      });

      it('still emits ready', () => {
        expectReadyOnce();
      });
    });

    describe('when the permission of the most frecent group is unknown', () => {
      beforeEach(async () => {
        createWrapper({
          frecentGroupsHandler: respondWithFrecentGroups([mockAcme]),
          organizationGroupHandler: respondWithOrganizationGroup([
            { ...mockAcme, userPermissions: groupPermissions(null) },
          ]),
          props: { requirePermissions },
        });
        await waitForPromises();
      });

      it('derives the default from it', () => {
        expect(findSelectedNames()).toEqual([mockAcme.name]);
        expect(wrapper.emitted('change')).toEqual([[[asNamespace(mockAcme)]]]);
      });
    });
  });
});
