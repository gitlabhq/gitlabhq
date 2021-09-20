import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import {
  conanMetadata,
  mavenMetadata,
  nugetMetadata,
  packageData,
  composerMetadata,
  pypiMetadata,
} from 'jest/packages_and_registries/package_registry/mock_data';
import component from '~/packages_and_registries/package_registry/components/details/additional_metadata.vue';
import {
  PACKAGE_TYPE_NUGET,
  PACKAGE_TYPE_CONAN,
  PACKAGE_TYPE_MAVEN,
  PACKAGE_TYPE_NPM,
  PACKAGE_TYPE_COMPOSER,
  PACKAGE_TYPE_PYPI,
} from '~/packages_and_registries/package_registry/constants';

const mavenPackage = { packageType: PACKAGE_TYPE_MAVEN, metadata: mavenMetadata() };
const conanPackage = { packageType: PACKAGE_TYPE_CONAN, metadata: conanMetadata() };
const nugetPackage = { packageType: PACKAGE_TYPE_NUGET, metadata: nugetMetadata() };
const composerPackage = { packageType: PACKAGE_TYPE_COMPOSER, metadata: composerMetadata() };
const pypiPackage = { packageType: PACKAGE_TYPE_PYPI, metadata: pypiMetadata() };
const npmPackage = { packageType: PACKAGE_TYPE_NPM, metadata: {} };

describe('Package Additional Metadata', () => {
  let wrapper;
  const defaultProps = {
    packageEntity: {
      ...packageData(mavenPackage),
    },
  };

  const mountComponent = (props) => {
    wrapper = shallowMountExtended(component, {
      propsData: { ...defaultProps, ...props },
      stubs: {
        component: { template: '<div data-testid="component-is"></div>' },
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findTitle = () => wrapper.findByTestId('title');
  const findMainArea = () => wrapper.findByTestId('main');
  const findComponentIs = () => wrapper.findByTestId('component-is');

  it('has the correct title', () => {
    mountComponent();

    const title = findTitle();

    expect(title.exists()).toBe(true);
    expect(title.text()).toBe('Additional Metadata');
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
    `It is $visible that the component is visible when the package is $packageType`,
    ({ packageEntity, visible }) => {
      mountComponent({ packageEntity });

      expect(findTitle().exists()).toBe(visible);
      expect(findMainArea().exists()).toBe(visible);
      expect(findComponentIs().exists()).toBe(visible);

      if (visible) {
        expect(findComponentIs().props('packageEntity')).toEqual(packageEntity);
      }
    },
  );
});
