import { GlTable, GlButton } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import TokenProjectsTable from '~/token_access/components/token_projects_table.vue';
import { mockProjects, mockFields } from './mock_data';

describe('Token projects table', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = mountExtended(TokenProjectsTable, {
      provide: {
        fullPath: 'root/ci-project',
      },
      propsData: {
        tableFields: mockFields,
        projects: mockProjects,
      },
    });
  };

  const findTable = () => wrapper.findComponent(GlTable);
  const findDeleteProjectBtn = () => wrapper.findComponent(GlButton);
  const findAllDeleteProjectBtn = () => wrapper.findAllComponents(GlButton);
  const findAllTableRows = () => wrapper.findAllByTestId('projects-token-table-row');
  const findProjectNameCell = () => wrapper.findByTestId('token-access-project-name');
  const findProjectNamespaceCell = () => wrapper.findByTestId('token-access-project-namespace');

  beforeEach(() => {
    createComponent();
  });

  it('displays a table', () => {
    expect(findTable().exists()).toBe(true);
  });

  it('displays the correct amount of table rows', () => {
    expect(findAllTableRows()).toHaveLength(mockProjects.length);
  });

  it('delete project button emits event with correct project to delete', async () => {
    await findDeleteProjectBtn().trigger('click');

    expect(wrapper.emitted('removeProject')).toEqual([[mockProjects[0].fullPath]]);
  });

  it('does not show the remove icon if the project is locked', () => {
    // currently two mock projects with one being a locked project
    expect(findAllDeleteProjectBtn()).toHaveLength(1);
  });

  it('displays project and namespace cells', () => {
    expect(findProjectNameCell().text()).toBe('merge-train-stuff');
    expect(findProjectNamespaceCell().text()).toBe('root');
  });
});
