import { GlTable, GlButton } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import TokenProjectsTable from '~/token_access/components/token_projects_table.vue';
import { mockProjects, mockFields } from './mock_data';

describe('Token projects table', () => {
  let wrapper;

  const defaultProps = {
    tableFields: mockFields,
    projects: mockProjects,
  };

  const createComponent = (props) => {
    wrapper = mountExtended(TokenProjectsTable, {
      provide: {
        fullPath: 'root/ci-project',
      },
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const findTable = () => wrapper.findComponent(GlTable);
  const findDeleteProjectBtn = () => wrapper.findComponent(GlButton);
  const findAllDeleteProjectBtn = () => wrapper.findAllComponents(GlButton);
  const findAllTableRows = () => wrapper.findAllByTestId('projects-token-table-row');
  const findProjectNameCell = () => wrapper.findByTestId('token-access-project-name');

  it('displays a table', () => {
    createComponent();

    expect(findTable().exists()).toBe(true);
  });

  it('displays the correct amount of table rows', () => {
    createComponent();

    expect(findAllTableRows()).toHaveLength(mockProjects.length);
  });

  it('delete project button emits event with correct project to delete', async () => {
    createComponent();

    await findDeleteProjectBtn().trigger('click');

    expect(wrapper.emitted('removeProject')).toEqual([[mockProjects[0].fullPath]]);
  });

  it('does not show the remove icon if the project is locked', () => {
    createComponent();

    // currently two mock projects with one being a locked project
    expect(findAllDeleteProjectBtn()).toHaveLength(1);
  });

  it('displays project fullpath', () => {
    createComponent();

    expect(findProjectNameCell().text()).toBe('root/merge-train-stuff');
  });
});
