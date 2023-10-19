import { GlCollapsibleListbox } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ProjectsDropdown from '~/integrations/gitlab_slack_application/components/projects_dropdown.vue';

describe('Slack application projects dropdown', () => {
  let wrapper;

  const projectsMockData = [
    {
      avatar_url: null,
      id: 1,
      name: 'Gitlab Smoke Tests',
      name_with_namespace: 'Toolbox / Gitlab Smoke Tests',
    },
    {
      avatar_url: null,
      id: 2,
      name: 'Gitlab Test',
      name_with_namespace: 'Gitlab Org / Gitlab Test',
    },
    {
      avatar_url: 'foo/bar',
      id: 3,
      name: 'Gitlab Shell',
      name_with_namespace: 'Gitlab Org / Gitlab Shell',
    },
  ];

  const createComponent = (props = {}) => {
    wrapper = shallowMount(ProjectsDropdown, {
      propsData: {
        projects: projectsMockData,
        ...props,
      },
    });
  };

  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);

  beforeEach(() => {
    createComponent();
  });

  it('renders the listbox with 3 items', () => {
    expect(findListbox().exists()).toBe(true);
    expect(findListbox().props('items')).toHaveLength(3);
  });

  it('should emit project-selected if a project is clicked', () => {
    findListbox().vm.$emit('select', 1);

    expect(wrapper.emitted('project-selected')).toMatchObject([[projectsMockData[0]]]);
  });
});
