import { mount } from '@vue/test-utils';
import { GlAlert, GlLoadingIcon, GlTable, GlAvatar } from '@gitlab/ui';
import { visitUrl, joinPaths } from '~/lib/utils/url_utility';
import IncidentsList from '~/incidents/components/incidents_list.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { I18N } from '~/incidents/constants';
import mockIncidents from '../mocks/incidents.json';

jest.mock('~/lib/utils/url_utility', () => ({
  visitUrl: jest.fn().mockName('visitUrlMock'),
  joinPaths: jest.fn().mockName('joinPaths'),
  mergeUrlParams: jest.fn().mockName('mergeUrlParams'),
}));

describe('Incidents List', () => {
  let wrapper;
  const newIssuePath = 'namespace/project/-/issues/new';
  const incidentTemplateName = 'incident';

  const findTable = () => wrapper.find(GlTable);
  const findTableRows = () => wrapper.findAll('table tbody tr');
  const findAlert = () => wrapper.find(GlAlert);
  const findLoader = () => wrapper.find(GlLoadingIcon);
  const findTimeAgo = () => wrapper.findAll(TimeAgoTooltip);
  const findAssingees = () => wrapper.findAll('[data-testid="incident-assignees"]');
  const findCreateIncidentBtn = () => wrapper.find('[data-testid="createIncidentBtn"]');

  function mountComponent({ data = { incidents: [] }, loading = false }) {
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
        issuePath: '/project/isssues',
      },
      stubs: {
        GlButton: true,
        GlAvatar: true,
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

  it('shows empty state', () => {
    mountComponent({
      data: { incidents: [] },
      loading: false,
    });
    expect(findTable().text()).toContain(I18N.noIncidents);
  });

  it('shows error state', () => {
    mountComponent({
      data: { incidents: [], errored: true },
      loading: false,
    });
    expect(findTable().text()).toContain(I18N.noIncidents);
    expect(findAlert().exists()).toBe(true);
  });

  describe('Incident Management list', () => {
    beforeEach(() => {
      mountComponent({
        data: { incidents: mockIncidents },
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

      it('contains a link to the issue details', () => {
        findTableRows()
          .at(0)
          .trigger('click');
        expect(visitUrl).toHaveBeenCalledWith(joinPaths(`/project/isssues/`, mockIncidents[0].iid));
      });
    });
  });

  describe('Create Incident', () => {
    beforeEach(() => {
      mountComponent({
        data: { incidents: [] },
        loading: false,
      });
    });

    it('shows the button linking to new incidents page with prefilled incident template', () => {
      expect(findCreateIncidentBtn().exists()).toBe(true);
    });

    it('sets button loading on click', () => {
      findCreateIncidentBtn().vm.$emit('click');
      return wrapper.vm.$nextTick().then(() => {
        expect(findCreateIncidentBtn().attributes('loading')).toBe('true');
      });
    });
  });
});
