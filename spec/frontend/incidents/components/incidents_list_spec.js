import { mount } from '@vue/test-utils';
import { GlAlert, GlLoadingIcon, GlTable } from '@gitlab/ui';
import IncidentsList from '~/incidents/components/incidents_list.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { I18N } from '~/incidents/constants';
import mockIncidents from '../mocks/incidents.json';

describe('Incidents List', () => {
  let wrapper;

  const findTable = () => wrapper.find(GlTable);
  const findTableRows = () => wrapper.findAll('table tbody tr');
  const findAlert = () => wrapper.find(GlAlert);
  const findLoader = () => wrapper.find(GlLoadingIcon);
  const findTimeAgo = () => wrapper.findAll(TimeAgoTooltip);

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
  });
});
