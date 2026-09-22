import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlButton, GlCollapsibleListbox } from '@gitlab/ui';
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

  const mockGroup = {
    __typename: TYPENAME_GROUP,
    id: 'gid://gitlab/Group/1',
    name: 'GitLab.org',
    fullName: 'GitLab.org',
    fullPath: groupFullPath,
  };

  const mockProject = (id, name, path) => ({
    __typename: TYPENAME_PROJECT,
    id: `gid://gitlab/Project/${id}`,
    name,
    fullName: `GitLab.org / ${name}`,
    fullPath: `${groupFullPath}/${path}`,
  });

  const mockSubgroup = ({ id, name, path, projectsCount = 0, descendantGroupsCount = 0 }) => ({
    __typename: TYPENAME_GROUP,
    id: `gid://gitlab/Group/${id}`,
    name,
    fullName: `GitLab.org / ${name}`,
    fullPath: `${groupFullPath}/${path}`,
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
  };

  const respondWithScopeNamespace = ({ group = null, projects = [] } = {}) =>
    jest.fn().mockResolvedValue({
      data: {
        group,
        projects: { __typename: 'ProjectConnection', nodes: projects },
      },
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
  });

  // The real listbox takes either grouped sections or a flat option list, rendering its
  // list-item slot per option either way.
  const listboxStub = stubComponent(GlCollapsibleListbox, {
    template: `
      <div>
        <div v-for="(item, index) in flatItems" :key="item.value || index">
          <slot name="list-item" :item="item"></slot>
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
      propsData: { ...props },
      stubs: { GlCollapsibleListbox: listboxStub },
    });
  };

  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findSections = () => findListbox().props('items');
  const findOptions = () => findSections().flatMap((item) => item.options ?? item);
  const findDoneButton = () => wrapper.findComponent(GlButton);
  const findItems = () => wrapper.findAllComponents(ScopePickerItem);
  const findEmptyItem = () => wrapper.findByTestId('scope-picker-empty-item');
  const findItemFor = ({ fullPath }) =>
    findItems().wrappers.find((item) => item.props('value') === fullPath);
  const findItemTexts = () => findItems().wrappers.map((item) => item.props('text'));
  const findItemValues = () => findItems().wrappers.map((item) => item.props('value'));
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

        expect(wrapper.emitted('change')).toEqual([[asNamespace(mockCapsuleCorp)]]);
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

        expect(wrapper.emitted('change').at(-1)).toEqual([asNamespace(mockDeepProject)]);
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
        await search('charts');
      });

      it('goes on naming the selection the consumer still holds', () => {
        expect(findListbox().props('toggleText')).toBe(mockDeepProject.name);
      });

      it('emits no change, nothing about the selection having been touched', () => {
        expect(wrapper.emitted('change')).toEqual([[asNamespace(mockDeepProject)]]);
      });

      // Otherwise the listbox takes the toggle for an empty picker and greys the name it shows.
      it('holds the selection, none of the rows on screen carrying it', () => {
        expect(findListbox().props('selected')).toEqual([mockDeepProject.fullPath]);
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

      it('marks the listbox as searching, leaving the whole-dropdown spinner alone', () => {
        expect(findListbox().props('searching')).toBe(true);
        expect(findListbox().props('loading')).toBe(false);
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

      it('renders no items, leaving the listbox to say so', () => {
        expect(findItems()).toHaveLength(0);
        expect(findListbox().props('noResultsText')).toBe('No groups or projects found');
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
        expect(findListbox().props('searching')).toBe(false);
      });

      it('emits error', () => {
        expect(wrapper.emitted('error')).toEqual([[error]]);
      });

      it('logs the error to sentry', () => {
        expect(sentryBrowserWrapper.captureException).toHaveBeenCalledWith(error);
      });
    });
  });

  describe('an initial path, as the `scope` URL param supplies', () => {
    const initialPath = mockFrontend.fullPath;

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

    it('does not look anything up when no path is given', async () => {
      createWrapper();
      await waitForPromises();

      expect(scopeNamespaceRequestHandler).not.toHaveBeenCalled();
      expect(findListbox().props('toggleText')).toBe('Select a group or project');
    });

    // The path alone does not say which kind it is, so both sides go in the same request.
    it('looks the path up as both a group and a project', () => {
      createWrapper({ props: { initialPath } });

      expect(scopeNamespaceRequestHandler).toHaveBeenCalledWith({
        fullPath: initialPath,
        fullPaths: [initialPath],
      });
    });

    // The list is browsable without it, and the filter bar remounts on every view switch, so
    // gating the list on the lookup flashed loading each time.
    it('leaves the list usable while the lookup is outstanding, naming the toggle once it lands', async () => {
      const lookup = deferLookup();
      createWrapper({ props: { initialPath }, scopeNamespaceHandler: lookup.handler });
      await waitForPromises();

      expect(findListbox().props('loading')).toBe(false);
      expect(findListbox().props('toggleText')).toBe('Select a group or project');

      lookup.resolve(respondWithGroup(mockFrontend));
      await waitForPromises();

      expect(findListbox().props('toggleText')).toBe(mockFrontend.name);
    });

    describe('when the path is a group', () => {
      beforeEach(async () => {
        createWrapper({
          props: { initialPath: mockCapsuleCorp.fullPath },
          scopeNamespaceHandler: respondWithScopeNamespace({ group: mockCapsuleCorp }),
        });
        await waitForPromises();
      });

      it('names it on the toggle', () => {
        expect(findListbox().props('toggleText')).toBe(mockCapsuleCorp.name);
      });

      it('marks its row selected', () => {
        expect(findListbox().props('selected')).toEqual([mockCapsuleCorp.fullPath]);
      });

      // Emitted like a click, so the page applies it as an ordinary filter change.
      it('emits it as a change', () => {
        expect(wrapper.emitted('change')).toEqual([[asNamespace(mockCapsuleCorp)]]);
      });
    });

    describe('when the path is a project', () => {
      beforeEach(async () => {
        createWrapper({
          props: { initialPath: mockScopeProject.fullPath },
          scopeNamespaceHandler: respondWithScopeNamespace({ projects: [mockScopeProject] }),
        });
        await waitForPromises();
      });

      it('names it on the toggle', () => {
        expect(findListbox().props('toggleText')).toBe(mockScopeProject.name);
      });

      it('emits it as a change, typed as a project', () => {
        expect(wrapper.emitted('change')).toEqual([[asNamespace(mockScopeProject)]]);
      });

      it('allows a non-loaded item to be selected by default', () => {
        expect(findListbox().props('selected')).toEqual([mockScopeProject.fullPath]);
        expect(findItemValues()).not.toContain(mockScopeProject.fullPath);
      });
    });

    // Renamed, deleted, or not visible to this user.
    describe('when the path resolves to neither', () => {
      beforeEach(async () => {
        createWrapper({
          props: { initialPath },
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
    });

    describe('when the lookup fails', () => {
      const error = new Error('nope');

      beforeEach(async () => {
        createWrapper({
          props: { initialPath },
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
        expect(findListbox().props('selected')).toEqual([]);
      });
    });

    // The page hands its current selection back down through this prop, so it changes on every
    // pick, not just the ones that came from the URL.
    describe('when the page echoes a pick back through the prop', () => {
      beforeEach(async () => {
        createWrapper();
        await waitForPromises();

        await toggleSelected(mockCapsuleCorp);
        await wrapper.setProps({ initialPath: mockCapsuleCorp.fullPath });
      });

      it('looks nothing up, the click having already resolved the namespace', () => {
        expect(scopeNamespaceRequestHandler).not.toHaveBeenCalled();
      });

      it('keeps the pick', () => {
        expect(findListbox().props('selected')).toEqual([mockCapsuleCorp.fullPath]);
      });
    });

    describe('when the user picks something before the lookup lands', () => {
      beforeEach(async () => {
        const lookup = deferLookup();
        createWrapper({ props: { initialPath }, scopeNamespaceHandler: lookup.handler });
        await waitForPromises();

        await toggleSelected(mockCapsuleCorp);

        lookup.resolve(respondWithGroup(mockFrontend));
        await waitForPromises();
      });

      // The pick is the more recent intent, so the arriving param must not stomp it.
      it('keeps what the user picked', () => {
        expect(findListbox().props('selected')).toEqual([mockCapsuleCorp.fullPath]);
        expect(findListbox().props('toggleText')).toBe(mockCapsuleCorp.name);
      });
    });
  });

  describe('a default derived from the most frecent group', () => {
    const asFrecentGroup = ({ id, name, fullName, fullPath }) => ({
      __typename: TYPENAME_GROUP,
      id,
      name,
      fullName,
      fullPath,
    });

    const mockFrecentGroups = [asFrecentGroup(mockAcme), asFrecentGroup(mockCapsuleCorp)];
    const error = new Error('no such luck');
    const rejecting = () => jest.fn().mockRejectedValue(error);

    // Leaves the frecent lookup outstanding once the browse queries have settled, so a pick can
    // be made while it is still in flight.
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
        expect(findListbox().props('selected')).toEqual([mockAcme.fullPath]);
      });

      it('emits it as a change', () => {
        expect(wrapper.emitted('change')).toEqual([[asNamespace(mockAcme)]]);
      });
    });

    describe('when the `scope` URL param already names one', () => {
      beforeEach(async () => {
        createWrapper({
          props: { initialPath: mockCapsuleCorp.fullPath },
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
        expect(findListbox().props('selected')).toEqual([mockCapsuleCorp.fullPath]);
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

      it('emits the cleared selection', () => {
        expect(wrapper.emitted('change')).toEqual([[asNamespace(mockAcme)], [null]]);
      });
    });

    describe('when the user picks something before it lands', () => {
      beforeEach(async () => {
        const lookup = deferFrecentGroups();
        createWrapper({ frecentGroupsHandler: lookup.handler });
        await waitForPromises();

        await toggleSelected(mockCapsuleCorp);

        lookup.resolve({ data: { frecentGroups: mockFrecentGroups } });
        await waitForPromises();
      });

      // The pick is the more recent intent, so a default arriving behind it must not stomp it.
      it('keeps what the user picked', () => {
        expect(findListbox().props('selected')).toEqual([mockCapsuleCorp.fullPath]);
        expect(findListbox().props('toggleText')).toBe(mockCapsuleCorp.name);
      });
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
    });
  });
});
