import { GlAlert, GlLoadingIcon, GlTable, GlAvatar, GlEmptyState } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import IncidentsList from '~/incidents/components/incidents_list.vue';
import {
  I18N,
  TH_CREATED_AT_TEST_ID,
  TH_SEVERITY_TEST_ID,
  TH_PUBLISHED_TEST_ID,
  TH_INCIDENT_SLA_TEST_ID,
  trackIncidentCreateNewOptions,
  trackIncidentListViewsOptions,
} from '~/incidents/constants';
import { visitUrl, joinPaths, mergeUrlParams } from '~/lib/utils/url_utility';
import SeverityToken from '~/sidebar/components/severity/severity.vue';
import Tracking from '~/tracking';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import mockIncidents from '../mocks/incidents.json';

jest.mock('~/lib/utils/url_utility', () => ({
  visitUrl: jest.fn().mockName('visitUrlMock'),
  joinPaths: jest.fn(),
  mergeUrlParams: jest.fn(),
  setUrlParams: jest.fn(),
  updateHistory: jest.fn(),
}));
jest.mock('~/tracking');

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
  const findAssignees = () => wrapper.findAll('[data-testid="incident-assignees"]');
  const findCreateIncidentBtn = () => wrapper.find('[data-testid="createIncidentBtn"]');
  const findClosedIcon = () => wrapper.findAll("[data-testid='incident-closed']");
  const findEmptyState = () => wrapper.find(GlEmptyState);
  const findSeverity = () => wrapper.findAll(SeverityToken);

  function mountComponent({ data = {}, loading = false, provide = {} } = {}) {
    wrapper = mount(IncidentsList, {
      data() {
        return {
          incidents: [],
          incidentsCount: {},
          ...data,
        };
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
        authorUsernameQuery: '',
        assigneeUsernameQuery: '',
        slaFeatureAvailable: true,
        ...provide,
      },
      stubs: {
        GlButton: true,
        GlAvatar: true,
        GlEmptyState: true,
        ServiceLevelAgreementCell: true,
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
        expect(findAssignees().at(0).text()).toBe(I18N.unassigned);
      });

      it('renders an avatar component when there is an assignee', () => {
        const avatar = findAssignees().at(1).find(GlAvatar);
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
      findTableRows().at(0).trigger('click');
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

    it('shows the button linking to new incidents page with pre-filled incident template when clicked', () => {
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

    it('should track create new incident button', async () => {
      findCreateIncidentBtn().vm.$emit('click');
      await wrapper.vm.$nextTick();
      expect(Tracking.event).toHaveBeenCalled();
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
      description        | selector                   | initialSort | firstSort   | nextSort
      ${'creation date'} | ${TH_CREATED_AT_TEST_ID}   | ${descSort} | ${ascSort}  | ${descSort}
      ${'severity'}      | ${TH_SEVERITY_TEST_ID}     | ${noneSort} | ${descSort} | ${ascSort}
      ${'publish date'}  | ${TH_PUBLISHED_TEST_ID}    | ${noneSort} | ${descSort} | ${ascSort}
      ${'due date'}      | ${TH_INCIDENT_SLA_TEST_ID} | ${noneSort} | ${ascSort}  | ${descSort}
    `(
      'updates sort with new direction when sorting by $description',
      async ({ selector, initialSort, firstSort, nextSort }) => {
        const [[attr, value]] = Object.entries(selector);
        const columnHeader = () => wrapper.find(`[${attr}="${value}"]`);
        expect(columnHeader().attributes('aria-sort')).toBe(initialSort);
        columnHeader().trigger('click');
        await wrapper.vm.$nextTick();
        expect(columnHeader().attributes('aria-sort')).toBe(firstSort);
        columnHeader().trigger('click');
        await wrapper.vm.$nextTick();
        expect(columnHeader().attributes('aria-sort')).toBe(nextSort);
      },
    );
  });

  describe('Snowplow tracking', () => {
    beforeEach(() => {
      mountComponent({
        data: { incidents: { list: mockIncidents }, incidentsCount: {} },
        loading: false,
      });
    });

    it('should track incident list views', () => {
      const { category, action } = trackIncidentListViewsOptions;
      expect(Tracking.event).toHaveBeenCalledWith(category, action);
    });

    it('should track incident creation events', async () => {
      findCreateIncidentBtn().vm.$emit('click');
      await wrapper.vm.$nextTick();
      const { category, action } = trackIncidentCreateNewOptions;
      expect(Tracking.event).toHaveBeenCalledWith(category, action);
    });
  });
});
