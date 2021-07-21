import { GlEmptyState } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash from '~/flash';

import PackagesApp from '~/packages_and_registries/package_registry/components/details/app.vue';
import PackageTitle from '~/packages_and_registries/package_registry/components/details/package_title.vue';
import { FETCH_PACKAGE_DETAILS_ERROR_MESSAGE } from '~/packages_and_registries/package_registry/constants';
import getPackageDetails from '~/packages_and_registries/package_registry/graphql/queries/get_package_details.query.graphql';
import { packageDetailsQuery, packageData } from '../../mock_data';

jest.mock('~/flash');

const localVue = createLocalVue();

describe('PackagesApp', () => {
  let wrapper;
  let apolloProvider;

  function createComponent({ resolver = jest.fn().mockResolvedValue(packageDetailsQuery()) } = {}) {
    localVue.use(VueApollo);

    const requestHandlers = [[getPackageDetails, resolver]];
    apolloProvider = createMockApollo(requestHandlers);

    wrapper = shallowMount(PackagesApp, {
      localVue,
      apolloProvider,
      provide: {
        packageId: '111',
        titleComponent: 'PackageTitle',
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

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findPackageTitle = () => wrapper.findComponent(PackageTitle);

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders an empty state component', () => {
    createComponent();

    expect(findEmptyState().exists()).toBe(true);
  });

  it('renders the app and displays the package title', async () => {
    createComponent();

    await waitForPromises();

    expect(findPackageTitle().exists()).toBe(true);
    expect(findPackageTitle().props()).toMatchObject({
      packageEntity: expect.objectContaining(packageData()),
    });
  });

  it('emits an error message if the load fails', async () => {
    createComponent({ resolver: jest.fn().mockRejectedValue() });

    await waitForPromises();

    expect(createFlash).toHaveBeenCalledWith(
      expect.objectContaining({
        message: FETCH_PACKAGE_DETAILS_ERROR_MESSAGE,
      }),
    );
  });
});
