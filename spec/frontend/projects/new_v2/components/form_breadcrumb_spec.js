import { GlBreadcrumb } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import FormBreadcrumb from '~/projects/new_v2/components/form_breadcrumb.vue';

describe('New project form breadcrumbs', () => {
  let wrapper;

  const createComponent = ({ props = {}, provide = {} } = {}) => {
    wrapper = shallowMountExtended(FormBreadcrumb, {
      propsData: {
        ...props,
      },
      provide: {
        rootPath: '/',
        projectsUrl: '/dashboard/projects',
        ...provide,
      },
    });
  };

  const findBreadcrumb = () => wrapper.findComponent(GlBreadcrumb);

  it('renders personal namespace breadcrumbs', () => {
    createComponent({ provide: { parentGroupUrl: null, parentGroupName: null } });

    expect(findBreadcrumb().props('items')).toStrictEqual([
      { text: 'Your work', href: '/' },
      { text: 'Projects', href: '/dashboard/projects' },
      { text: 'New project', href: '#' },
    ]);
  });

  it('renders group namespace breadcrumbs', () => {
    createComponent({
      provide: { parentGroupUrl: '/group/projects', parentGroupName: 'test group' },
    });

    expect(findBreadcrumb().props('items')).toStrictEqual([
      { text: 'test group', href: '/group/projects' },
      { text: 'New project', href: '#' },
    ]);
  });

  it('renders breadcrumbs with additional hash', () => {
    createComponent({
      props: {
        selectedProjectType: {
          key: 'blank',
          value: 'blank_project',
          selector: '#blank-project-pane',
          title: 'Create blank project',
          description:
            'Create a blank project to store your files, plan your work, and collaborate on code, among other things.',
        },
      },
      provide: { parentGroupUrl: null, parentGroupName: null },
    });

    expect(findBreadcrumb().props('items')).toStrictEqual([
      { text: 'Your work', href: '/' },
      { text: 'Projects', href: '/dashboard/projects' },
      { text: 'New project', href: '#' },
      { text: 'Create blank project', href: '#blank_project' },
    ]);
  });
});
