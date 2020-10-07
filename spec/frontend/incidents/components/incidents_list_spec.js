import { mount } from '@vue/test-utils';
import {
  GlAlert,
  GlLoadingIcon,
  GlTable,
  GlAvatar,
  GlPagination,
  GlTab,
  GlTabs,
  GlBadge,
  GlEmptyState,
} from '@gitlab/ui';
import { visitUrl, joinPaths, mergeUrlParams } from '~/lib/utils/url_utility';
import IncidentsList from '~/incidents/components/incidents_list.vue';
import SeverityToken from '~/sidebar/components/severity/severity.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import AuthorToken from '~/vue_shared/components/filtered_search_bar/tokens/author_token.vue';
import {
  I18N,
  INCIDENT_STATUS_TABS,
  TH_CREATED_AT_TEST_ID,
  TH_SEVERITY_TEST_ID,
  TH_PUBLISHED_TEST_ID,
} from '~/incidents/constants';
import mockIncidents from '../mocks/incidents.json';
import mockFilters from '../mocks/incidents_filter.json';

jest.mock('~/lib/utils/url_utility', () => ({
  visitUrl: jest.fn().mockName('visitUrlMock'),
  joinPaths: jest.fn(),
  mergeUrlParams: jest.fn(),
  setUrlParams: jest.fn(),
  updateHistory: jest.fn(),
}));

describe('Incidents List', () => {
  let wrapper;
  const newIssuePath = 'namespace/project/-/issues/new';
  const emptyListSvgPath = '/assets/empty.svg';
  const incidentTemplateName = 'incident';
  const incidentType = 'incident';
  const incidentsCount = {
    opened: 24,
    closed: 10,
    all: 26,
  };

  const findTable = () => wrapper.find(GlTable);
  const findTableRows = () => wrapper.findAll('table tbody tr');
  const findAlert = () => wrapper.find(GlAlert);
  const findLoader = () => wrapper.find(GlLoadingIcon);
  const findTimeAgo = () => wrapper.findAll(TimeAgoTooltip);
  const findSearch = () => wrapper.find(FilteredSearchBar);
  const findAssingees = () => wrapper.findAll('[data-testid="incident-assignees"]');
  const findCreateIncidentBtn = () => wrapper.find('[data-testid="createIncidentBtn"]');
  const findClosedIcon = () => wrapper.findAll("[data-testid='incident-closed']");
  const findPagination = () => wrapper.find(GlPagination);
  const findStatusFilterTabs = () => wrapper.findAll(GlTab);
  const findStatusFilterBadge = () => wrapper.findAll(GlBadge);
  const findStatusTabs = () => wrapper.find(GlTabs);
  const findEmptyState = () => wrapper.find(GlEmptyState);
  const findSeverity = () => wrapper.findAll(SeverityToken);

  function mountComponent({ data = { incidents: [], incidentsCount: {} }, loading = false }) {
    wrapper = mount(IncidentsList, {
      data() {
        return data;
      },
      mocks: {
        $apollo: {
          queries: {
            incidents: {
              loading,
            },
          },
        },
      },
      provide: {
        projectPath: '/project/path',
        newIssuePath,
        incidentTemplateName,
        incidentType,
        issuePath: '/project/issues',
        publishedAvailable: true,
        emptyListSvgPath,
        textQuery: '',
        authorUsernamesQuery: '',
        assigneeUsernamesQuery: '',
      },
      stubs: {
        GlButton: true,
        GlAvatar: true,
        GlEmptyState: true,
      },
    });
  }

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  it('shows the loading state', () => {
    mountComponent({
      loading: true,
    });
    expect(findLoader().exists()).toBe(true);
  });

  describe('empty state', () => {
    const {
      emptyState: { title, emptyClosedTabTitle, description },
    } = I18N;

    it.each`
      statusFilter | all  | closed | expectedTitle          | expectedDescription
      ${'all'}     | ${2} | ${1}   | ${title}               | ${description}
      ${'open'}    | ${2} | ${0}   | ${title}               | ${description}
      ${'closed'}  | ${0} | ${0}   | ${title}               | ${description}
      ${'closed'}  | ${2} | ${0}   | ${emptyClosedTabTitle} | ${undefined}
    `(
      `when active tab is $statusFilter and there are $all incidents in total and $closed closed incidents, the empty state
      has title: $expectedTitle and description: $expectedDescription`,
      ({ statusFilter, all, closed, expectedTitle, expectedDescription }) => {
        mountComponent({
          data: { incidents: { list: [] }, incidentsCount: { all, closed }, statusFilter },
          loading: false,
        });
        expect(findEmptyState().exists()).toBe(true);
        expect(findEmptyState().attributes('title')).toBe(expectedTitle);
        expect(findEmptyState().attributes('description')).toBe(expectedDescription);
      },
    );
  });

  it('shows error state', () => {
    mountComponent({
      data: { incidents: { list: [] }, incidentsCount: { all: 0 }, errored: true },
      loading: false,
    });
    expect(findTable().text()).toContain(I18N.noIncidents);
    expect(findAlert().exists()).toBe(true);
  });

  describe('Incident Management list', () => {
    beforeEach(() => {
      mountComponent({
        data: { incidents: { list: mockIncidents }, incidentsCount },
        loading: false,
      });
    });

    it('renders rows based on provided data', () => {
      expect(findTableRows().length).toBe(mockIncidents.length);
    });

    it('renders a createdAt with timeAgo component per row', () => {
      expect(findTimeAgo().length).toBe(mockIncidents.length);
    });

    describe('Assignees', () => {
      it('shows Unassigned when there are no assignees', () => {
        expect(
          findAssingees()
            .at(0)
            .text(),
        ).toBe(I18N.unassigned);
      });

      it('renders an avatar component when there is an assignee', () => {
        const avatar = findAssingees()
          .at(1)
          .find(GlAvatar);
        const { src, label } = avatar.attributes();
        const { name, avatarUrl } = mockIncidents[1].assignees.nodes[0];

        expect(avatar.exists()).toBe(true);
        expect(label).toBe(name);
        expect(src).toBe(avatarUrl);
      });

      it('renders a closed icon for closed incidents', () => {
        expect(findClosedIcon().length).toBe(
          mockIncidents.filter(({ state }) => state === 'closed').length,
        );
      });
    });

    it('renders severity per row', () => {
      expect(findSeverity().length).toBe(mockIncidents.length);
    });

    it('contains a link to the incident details page', async () => {
      findTableRows()
        .at(0)
        .trigger('click');
      expect(visitUrl).toHaveBeenCalledWith(
        joinPaths(`/project/issues/incident`, mockIncidents[0].iid),
      );
    });
  });

  describe('Create Incident', () => {
    beforeEach(() => {
      mountComponent({
        data: { incidents: { list: mockIncidents }, incidentsCount: {} },
        loading: false,
      });
    });

    it('shows the button linking to new incidents page with prefilled incident template when clicked', () => {
      expect(findCreateIncidentBtn().exists()).toBe(true);
      findCreateIncidentBtn().trigger('click');
      expect(mergeUrlParams).toHaveBeenCalledWith(
        { issuable_template: incidentTemplateName, 'issue[issue_type]': incidentType },
        newIssuePath,
      );
    });

    it('sets button loading on click', async () => {
      findCreateIncidentBtn().vm.$emit('click');
      await wrapper.vm.$nextTick();
      expect(findCreateIncidentBtn().attributes('loading')).toBe('true');
    });

    it("doesn't show the button when list is empty", () => {
      mountComponent({
        data: { incidents: { list: [] }, incidentsCount: {} },
        loading: false,
      });
      expect(findCreateIncidentBtn().exists()).toBe(false);
    });
  });

  describe('Pagination', () => {
    beforeEach(() => {
      mountComponent({
        data: {
          incidents: {
            list: mockIncidents,
            pageInfo: { hasNextPage: true, hasPreviousPage: true },
          },
          incidentsCount,
          errored: false,
        },
        loading: false,
      });
    });

    it('should render pagination', () => {
      expect(wrapper.find(GlPagination).exists()).toBe(true);
    });

    describe('prevPage', () => {
      it('returns prevPage button', async () => {
        findPagination().vm.$emit('input', 3);

        await wrapper.vm.$nextTick();
        expect(
          findPagination()
            .findAll('.page-item')
            .at(0)
            .text(),
        ).toBe('Prev');
      });

      it('returns prevPage number', async () => {
        findPagination().vm.$emit('input', 3);

        await wrapper.vm.$nextTick();
        expect(wrapper.vm.prevPage).toBe(2);
      });

      it('returns 0 when it is the first page', async () => {
        findPagination().vm.$emit('input', 1);

        await wrapper.vm.$nextTick();
        expect(wrapper.vm.prevPage).toBe(0);
      });
    });

    describe('nextPage', () => {
      it('returns nextPage button', async () => {
        findPagination().vm.$emit('input', 3);

        await wrapper.vm.$nextTick();
        expect(
          findPagination()
            .findAll('.page-item')
            .at(1)
            .text(),
        ).toBe('Next');
      });

      it('returns nextPage number', async () => {
        mountComponent({
          data: {
            incidents: {
              list: [...mockIncidents, ...mockIncidents, ...mockIncidents],
              pageInfo: { hasNextPage: true, hasPreviousPage: true },
            },
            incidentsCount,
            errored: false,
          },
          loading: false,
        });
        findPagination().vm.$emit('input', 1);

        await wrapper.vm.$nextTick();
        expect(wrapper.vm.nextPage).toBe(2);
      });

      it('returns `null` when currentPage is already last page', async () => {
        findStatusTabs().vm.$emit('input', 1);
        findPagination().vm.$emit('input', 1);
        await wrapper.vm.$nextTick();
        expect(wrapper.vm.nextPage).toBeNull();
      });
    });

    describe('Filtered search component', () => {
      beforeEach(() => {
        mountComponent({
          data: {
            incidents: {
              list: mockIncidents,
              pageInfo: { hasNextPage: true, hasPreviousPage: true },
            },
            incidentsCount,
            errored: false,
          },
          loading: false,
        });
      });

      it('renders the search component for incidents', () => {
        expect(findSearch().props('searchInputPlaceholder')).toBe('Search or filter results…');
        expect(findSearch().props('tokens')).toEqual([
          {
            type: 'author_username',
            icon: 'user',
            title: 'Author',
            unique: true,
            symbol: '@',
            token: AuthorToken,
            operators: [{ value: '=', description: 'is', default: 'true' }],
            fetchPath: '/project/path',
            fetchAuthors: expect.any(Function),
          },
          {
            type: 'assignee_username',
            icon: 'user',
            title: 'Assignees',
            unique: true,
            symbol: '@',
            token: AuthorToken,
            operators: [{ value: '=', description: 'is', default: 'true' }],
            fetchPath: '/project/path',
            fetchAuthors: expect.any(Function),
          },
        ]);
        expect(findSearch().props('recentSearchesStorageKey')).toBe('incidents');
      });

      it('returns correctly applied filter search values', async () => {
        const searchTerm = 'foo';
        wrapper.setData({
          searchTerm,
        });

        await wrapper.vm.$nextTick();
        expect(wrapper.vm.filteredSearchValue).toEqual([searchTerm]);
      });

      it('updates props tied to getIncidents GraphQL query', () => {
        wrapper.vm.handleFilterIncidents(mockFilters);

        expect(wrapper.vm.authorUsername).toBe('root');
        expect(wrapper.vm.assigneeUsernames).toEqual('root2');
        expect(wrapper.vm.searchTerm).toBe(mockFilters[2].value.data);
      });

      it('updates props `searchTerm` and `authorUsername` with empty values when passed filters param is empty', () => {
        wrapper.setData({
          authorUsername: 'foo',
          searchTerm: 'bar',
        });

        wrapper.vm.handleFilterIncidents([]);

        expect(wrapper.vm.authorUsername).toBe('');
        expect(wrapper.vm.searchTerm).toBe('');
      });
    });

    describe('Status Filter Tabs', () => {
      beforeEach(() => {
        mountComponent({
          data: { incidents: { list: mockIncidents }, incidentsCount },
          loading: false,
          stubs: {
            GlTab: true,
          },
        });
      });

      it('should display filter tabs', () => {
        const tabs = findStatusFilterTabs().wrappers;

        tabs.forEach((tab, i) => {
          expect(tab.attributes('data-testid')).toContain(INCIDENT_STATUS_TABS[i].status);
        });
      });

      it('should display filter tabs with alerts count badge for each status', () => {
        const tabs = findStatusFilterTabs().wrappers;
        const badges = findStatusFilterBadge();

        tabs.forEach((tab, i) => {
          const status = INCIDENT_STATUS_TABS[i].status.toLowerCase();
          expect(tab.attributes('data-testid')).toContain(INCIDENT_STATUS_TABS[i].status);
          expect(badges.at(i).text()).toContain(incidentsCount[status]);
        });
      });
    });
  });

  describe('sorting the incident list by column', () => {
    beforeEach(() => {
      mountComponent({
        data: { incidents: { list: mockIncidents }, incidentsCount },
        loading: false,
      });
    });

    const descSort = 'descending';
    const ascSort = 'ascending';
    const noneSort = 'none';

    it.each`
      selector                 | initialSort | firstSort   | nextSort
      ${TH_CREATED_AT_TEST_ID} | ${descSort} | ${ascSort}  | ${descSort}
      ${TH_SEVERITY_TEST_ID}   | ${noneSort} | ${descSort} | ${ascSort}
      ${TH_PUBLISHED_TEST_ID}  | ${noneSort} | ${descSort} | ${ascSort}
    `('updates sort with new direction', async ({ selector, initialSort, firstSort, nextSort }) => {
      const [[attr, value]] = Object.entries(selector);
      const columnHeader = () => wrapper.find(`[${attr}="${value}"]`);
      expect(columnHeader().attributes('aria-sort')).toBe(initialSort);
      columnHeader().trigger('click');
      await wrapper.vm.$nextTick();
      expect(columnHeader().attributes('aria-sort')).toBe(firstSort);
      columnHeader().trigger('click');
      await wrapper.vm.$nextTick();
      expect(columnHeader().attributes('aria-sort')).toBe(nextSort);
    });
  });
});
