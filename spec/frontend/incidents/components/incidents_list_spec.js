import { mount } from '@vue/test-utils';
import { GlAlert, GlLoadingIcon, GlTable } from '@gitlab/ui';
import IncidentsList from '~/incidents/components/incidents_list.vue';
import { I18N } from '~/incidents/constants';

describe('Incidents List', () => {
  let wrapper;

  const findTable = () => wrapper.find(GlTable);
  const findTableRows = () => wrapper.findAll('table tbody tr');
  const findAlert = () => wrapper.find(GlAlert);
  const findLoader = () => wrapper.find(GlLoadingIcon);

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
      props: { alertManagementEnabled: true, userCanEnableAlertManagement: true },
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

  it('displays basic list', () => {
    const incidents = [
      { title: 1, assignees: [] },
      { title: 2, assignees: [] },
      { title: 3, assignees: [] },
    ];
    mountComponent({
      data: { incidents },
      loading: false,
    });
    expect(findTableRows().length).toBe(incidents.length);
  });
});
