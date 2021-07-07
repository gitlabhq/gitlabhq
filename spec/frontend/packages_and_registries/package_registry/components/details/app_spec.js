import { GlEmptyState } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import PackagesApp from '~/packages_and_registries/package_registry/components/details/app.vue';

describe('PackagesApp', () => {
  let wrapper;

  function createComponent() {
    wrapper = shallowMount(PackagesApp, {
      provide: {
        titleComponent: 'titleComponent',
        projectName: 'projectName',
        canDelete: 'canDelete',
        svgPath: 'svgPath',
        npmPath: 'npmPath',
        npmHelpPath: 'npmHelpPath',
        projectListUrl: 'projectListUrl',
        groupListUrl: 'groupListUrl',
      },
    });
  }

  const emptyState = () => wrapper.findComponent(GlEmptyState);

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders an empty state component', () => {
    createComponent();

    expect(emptyState().exists()).toBe(true);
  });
});
