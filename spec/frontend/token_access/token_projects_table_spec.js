import { GlTable, GlButton } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import TokenProjectsTable from '~/token_access/components/token_projects_table.vue';
import { mockProjects } from './mock_data';

describe('Token projects table', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = mount(TokenProjectsTable, {
      provide: {
        fullPath: 'root/ci-project',
      },
      propsData: {
        projects: mockProjects,
      },
    });
  };

  const findTable = () => wrapper.findComponent(GlTable);
  const findAllTableRows = () => wrapper.findAll('[data-testid="projects-token-table-row"]');
  const findDeleteProjectBtn = () => wrapper.findComponent(GlButton);
  const findAllDeleteProjectBtn = () => wrapper.findAllComponents(GlButton);

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
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
});
