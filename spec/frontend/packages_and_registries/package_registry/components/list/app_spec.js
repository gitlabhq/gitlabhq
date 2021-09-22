import { GlEmptyState, GlSprintf, GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PackageListApp from '~/packages_and_registries/package_registry/components/list/app.vue';
import PackageTitle from '~/packages_and_registries/package_registry/components/list/package_title.vue';

import * as packageUtils from '~/packages_and_registries/shared/utils';

jest.mock('~/lib/utils/common_utils');
jest.mock('~/flash');

describe('packages_list_app', () => {
  let wrapper;

  const PackageList = {
    name: 'package-list',
    template: '<div><slot name="empty-state"></slot></div>',
  };
  const GlLoadingIcon = { name: 'gl-loading-icon', template: '<div>loading</div>' };

  const findPackageTitle = () => wrapper.findComponent(PackageTitle);

  const mountComponent = () => {
    wrapper = shallowMountExtended(PackageListApp, {
      stubs: {
        GlEmptyState,
        GlLoadingIcon,
        PackageList,
        GlSprintf,
        GlLink,
      },
      provide: {
        packageHelpUrl: 'packageHelpUrl',
        emptyListIllustration: 'emptyListIllustration',
        emptyListHelpUrl: 'emptyListHelpUrl',
      },
    });
  };

  beforeEach(() => {
    jest.spyOn(packageUtils, 'getQueryParams').mockReturnValue({});
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders', () => {
    mountComponent();
    expect(wrapper.element).toMatchSnapshot();
  });

  it('has a package title', () => {
    mountComponent();

    expect(findPackageTitle().exists()).toBe(true);
  });
});
