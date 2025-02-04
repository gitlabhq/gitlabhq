import { GlBreadcrumb } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import FormBreadcrumb from '~/projects/new_v2/components/form_breadcrumb.vue';

describe('New project form breadcrumbs', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(FormBreadcrumb, {
      provide: {
        rootPath: '/',
        projectsUrl: '/dashboard/projects',
        ...props,
      },
    });
  };

  const findBreadcrumb = () => wrapper.findComponent(GlBreadcrumb);

  it('renders personal namespace breadcrumbs', () => {
    createComponent({ parentGroupUrl: null, parentGroupName: null });

    expect(findBreadcrumb().props('items')).toStrictEqual([
      { text: 'Your work', href: '/' },
      { text: 'Projects', href: '/dashboard/projects' },
      { text: 'New project', href: '#' },
    ]);
  });

  it('renders group namespace breadcrumbs', () => {
    createComponent({ parentGroupUrl: '/group/projects', parentGroupName: 'test group' });

    expect(findBreadcrumb().props('items')).toStrictEqual([
      { text: 'test group', href: '/group/projects' },
      { text: 'New project', href: '#' },
    ]);
  });
});
