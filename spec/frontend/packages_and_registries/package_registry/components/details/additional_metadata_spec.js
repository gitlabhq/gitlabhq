import { GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import {
  conanMetadata,
  mavenMetadata,
  nugetMetadata,
  packageData,
} from 'jest/packages_and_registries/package_registry/mock_data';
import component from '~/packages_and_registries/package_registry/components/details/additional_metadata.vue';
import {
  PACKAGE_TYPE_NUGET,
  PACKAGE_TYPE_CONAN,
  PACKAGE_TYPE_MAVEN,
  PACKAGE_TYPE_NPM,
} from '~/packages_and_registries/package_registry/constants';
import DetailsRow from '~/vue_shared/components/registry/details_row.vue';

const mavenPackage = { packageType: PACKAGE_TYPE_MAVEN, metadata: mavenMetadata() };
const conanPackage = { packageType: PACKAGE_TYPE_CONAN, metadata: conanMetadata() };
const nugetPackage = { packageType: PACKAGE_TYPE_NUGET, metadata: nugetMetadata() };
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
        DetailsRow,
        GlSprintf,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findTitle = () => wrapper.findByTestId('title');
  const findMainArea = () => wrapper.findByTestId('main');
  const findNugetSource = () => wrapper.findByTestId('nuget-source');
  const findNugetLicense = () => wrapper.findByTestId('nuget-license');
  const findConanRecipe = () => wrapper.findByTestId('conan-recipe');
  const findMavenApp = () => wrapper.findByTestId('maven-app');
  const findMavenGroup = () => wrapper.findByTestId('maven-group');
  const findElementLink = (container) => container.findComponent(GlLink);

  it('has the correct title', () => {
    mountComponent();

    const title = findTitle();

    expect(title.exists()).toBe(true);
    expect(title.text()).toBe('Additional Metadata');
  });

  it.each`
    packageEntity   | visible  | packageType
    ${mavenPackage} | ${true}  | ${PACKAGE_TYPE_MAVEN}
    ${conanPackage} | ${true}  | ${PACKAGE_TYPE_CONAN}
    ${nugetPackage} | ${true}  | ${PACKAGE_TYPE_NUGET}
    ${npmPackage}   | ${false} | ${PACKAGE_TYPE_NPM}
  `(
    `It is $visible that the component is visible when the package is $packageType`,
    ({ packageEntity, visible }) => {
      mountComponent({ packageEntity });

      expect(findTitle().exists()).toBe(visible);
      expect(findMainArea().exists()).toBe(visible);
    },
  );

  describe('nuget metadata', () => {
    beforeEach(() => {
      mountComponent({ packageEntity: nugetPackage });
    });

    it.each`
      name         | finderFunction      | text                                           | link            | icon
      ${'source'}  | ${findNugetSource}  | ${'Source project located at projectUrl'}      | ${'projectUrl'} | ${'project'}
      ${'license'} | ${findNugetLicense} | ${'License information located at licenseUrl'} | ${'licenseUrl'} | ${'license'}
    `('$name element', ({ finderFunction, text, link, icon }) => {
      const element = finderFunction();
      expect(element.exists()).toBe(true);
      expect(element.text()).toBe(text);
      expect(element.props('icon')).toBe(icon);
      expect(findElementLink(element).attributes('href')).toBe(nugetPackage.metadata[link]);
    });
  });

  describe('conan metadata', () => {
    beforeEach(() => {
      mountComponent({ packageEntity: conanPackage });
    });

    it.each`
      name        | finderFunction     | text                                                       | icon
      ${'recipe'} | ${findConanRecipe} | ${'Recipe: package-8/1.0.0@gitlab-org+gitlab-test/stable'} | ${'information-o'}
    `('$name element', ({ finderFunction, text, icon }) => {
      const element = finderFunction();
      expect(element.exists()).toBe(true);
      expect(element.text()).toBe(text);
      expect(element.props('icon')).toBe(icon);
    });
  });

  describe('maven metadata', () => {
    beforeEach(() => {
      mountComponent();
    });

    it.each`
      name       | finderFunction    | text                     | icon
      ${'app'}   | ${findMavenApp}   | ${'App name: appName'}   | ${'information-o'}
      ${'group'} | ${findMavenGroup} | ${'App group: appGroup'} | ${'information-o'}
    `('$name element', ({ finderFunction, text, icon }) => {
      const element = finderFunction();
      expect(element.exists()).toBe(true);
      expect(element.text()).toBe(text);
      expect(element.props('icon')).toBe(icon);
    });
  });
});
