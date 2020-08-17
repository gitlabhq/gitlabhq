import { mount } from '@vue/test-utils';
import ImportedProjectTableRow from '~/import_projects/components/imported_project_table_row.vue';
import ImportStatus from '~/import_projects/components/import_status.vue';
import { STATUSES } from '~/import_projects/constants';

describe('ImportedProjectTableRow', () => {
  let wrapper;
  const project = {
    importSource: {
      fullName: 'fullName',
      providerLink: 'providerLink',
    },
    importedProject: {
      id: 1,
      fullPath: 'fullPath',
      importSource: 'importSource',
    },
    importStatus: STATUSES.FINISHED,
  };

  function mountComponent() {
    wrapper = mount(ImportedProjectTableRow, { propsData: { project } });
  }

  beforeEach(() => {
    mountComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders an imported project table row', () => {
    const providerLink = wrapper.find('[data-testid=providerLink]');

    expect(providerLink.attributes().href).toMatch(project.importSource.providerLink);
    expect(providerLink.text()).toMatch(project.importSource.fullName);
    expect(wrapper.find('[data-testid=fullPath]').text()).toMatch(project.importedProject.fullPath);
    expect(wrapper.find(ImportStatus).props().status).toBe(project.importStatus);
    expect(wrapper.find('[data-testid=goToProject').attributes().href).toMatch(
      project.importedProject.fullPath,
    );
  });
});
