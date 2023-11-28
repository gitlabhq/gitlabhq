import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlAlert } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import {
  conanMetadata,
  mavenMetadata,
  nugetMetadata,
  packageData,
  composerMetadata,
  pypiMetadata,
  packageMetadataQuery,
} from 'jest/packages_and_registries/package_registry/mock_data';
import AdditionalMetadata from '~/packages_and_registries/package_registry/components/details/additional_metadata.vue';
import {
  FETCH_PACKAGE_METADATA_ERROR_MESSAGE,
  PACKAGE_TYPE_NUGET,
  PACKAGE_TYPE_CONAN,
  PACKAGE_TYPE_MAVEN,
  PACKAGE_TYPE_NPM,
  PACKAGE_TYPE_COMPOSER,
  PACKAGE_TYPE_PYPI,
} from '~/packages_and_registries/package_registry/constants';
import AdditionalMetadataLoader from '~/packages_and_registries/package_registry/components/details/additional_metadata_loader.vue';
import waitForPromises from 'helpers/wait_for_promises';
import getPackageMetadata from '~/packages_and_registries/package_registry/graphql/queries/get_package_metadata.query.graphql';

const mavenPackage = { packageType: PACKAGE_TYPE_MAVEN, metadata: mavenMetadata() };
const conanPackage = { packageType: PACKAGE_TYPE_CONAN, metadata: conanMetadata() };
const nugetPackage = { packageType: PACKAGE_TYPE_NUGET, metadata: nugetMetadata() };
const composerPackage = { packageType: PACKAGE_TYPE_COMPOSER, metadata: composerMetadata() };
const pypiPackage = { packageType: PACKAGE_TYPE_PYPI, metadata: pypiMetadata() };
const npmPackage = { packageType: PACKAGE_TYPE_NPM, metadata: {} };

Vue.use(VueApollo);

describe('Package Additional metadata', () => {
  let wrapper;
  let apolloProvider;

  const defaultProps = {
    packageId: packageData().id,
    packageType: PACKAGE_TYPE_MAVEN,
  };

  const mountComponent = ({
    props = {},
    resolver = jest.fn().mockResolvedValue(packageMetadataQuery(mavenPackage)),
  } = {}) => {
    const requestHandlers = [[getPackageMetadata, resolver]];
    apolloProvider = createMockApollo(requestHandlers);

    wrapper = shallowMountExtended(AdditionalMetadata, {
      apolloProvider,
      propsData: { ...defaultProps, ...props },
    });
  };

  beforeEach(() => {
    jest.spyOn(Sentry, 'captureException').mockImplementation();
  });

  const findTitle = () => wrapper.findByTestId('title');
  const findMainArea = () => wrapper.findByTestId('main');
  const findComponentIs = () => wrapper.findByTestId('component-is');
  const findAdditionalMetadataLoader = () => wrapper.findComponent(AdditionalMetadataLoader);
  const findPackageMetadataAlert = () => wrapper.findComponent(GlAlert);

  it('renders the loading container when loading', () => {
    mountComponent();

    expect(findAdditionalMetadataLoader().exists()).toBe(true);
  });

  it('does not render the loading container once resolved', async () => {
    mountComponent();
    await waitForPromises();

    expect(findAdditionalMetadataLoader().exists()).toBe(false);
    expect(Sentry.captureException).not.toHaveBeenCalled();
  });

  it('has the correct title', () => {
    mountComponent();

    const title = findTitle();

    expect(title.exists()).toBe(true);
    expect(title.text()).toMatchInterpolatedText(AdditionalMetadata.i18n.componentTitle);
  });

  it('does not render gl-alert', () => {
    mountComponent();

    expect(findPackageMetadataAlert().exists()).toBe(false);
  });

  it('renders gl-alert if load fails', async () => {
    mountComponent({ resolver: jest.fn().mockRejectedValue() });

    await waitForPromises();

    expect(findPackageMetadataAlert().exists()).toBe(true);
    expect(findPackageMetadataAlert().text()).toMatchInterpolatedText(
      FETCH_PACKAGE_METADATA_ERROR_MESSAGE,
    );
    expect(Sentry.captureException).toHaveBeenCalled();
  });

  it.each`
    packageEntity      | visible  | packageType
    ${mavenPackage}    | ${true}  | ${PACKAGE_TYPE_MAVEN}
    ${conanPackage}    | ${true}  | ${PACKAGE_TYPE_CONAN}
    ${nugetPackage}    | ${true}  | ${PACKAGE_TYPE_NUGET}
    ${composerPackage} | ${true}  | ${PACKAGE_TYPE_COMPOSER}
    ${pypiPackage}     | ${true}  | ${PACKAGE_TYPE_PYPI}
    ${npmPackage}      | ${false} | ${PACKAGE_TYPE_NPM}
  `(
    `component visibility is $visible when the package is $packageType`,
    async ({ packageEntity, visible, packageType }) => {
      const resolved = packageMetadataQuery(packageType);
      const resolver = jest.fn().mockResolvedValue(resolved);

      mountComponent({ props: { packageType }, resolver });

      await waitForPromises();
      await nextTick();

      expect(findTitle().exists()).toBe(visible);
      expect(findMainArea().exists()).toBe(visible);
      expect(findComponentIs().exists()).toBe(visible);

      if (visible) {
        expect(findComponentIs().props('packageMetadata')).toEqual(packageEntity.metadata);
      }
    },
  );
});
