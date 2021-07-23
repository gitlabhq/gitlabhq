import { GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { mavenPackage, conanPackage, nugetPackage, npmPackage } from 'jest/packages/mock_data';
import component from '~/packages_and_registries/package_registry/components/details/additional_metadata.vue';
import DetailsRow from '~/vue_shared/components/registry/details_row.vue';

describe('Package Additional Metadata', () => {
  let wrapper;
  const defaultProps = {
    packageEntity: { ...mavenPackage },
  };

  const mountComponent = (props) => {
    wrapper = shallowMount(component, {
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

  const findTitle = () => wrapper.find('[data-testid="title"]');
  const findMainArea = () => wrapper.find('[data-testid="main"]');
  const findNugetSource = () => wrapper.find('[data-testid="nuget-source"]');
  const findNugetLicense = () => wrapper.find('[data-testid="nuget-license"]');
  const findConanRecipe = () => wrapper.find('[data-testid="conan-recipe"]');
  const findMavenApp = () => wrapper.find('[data-testid="maven-app"]');
  const findMavenGroup = () => wrapper.find('[data-testid="maven-group"]');
  const findElementLink = (container) => container.find(GlLink);

  it('has the correct title', () => {
    mountComponent();

    const title = findTitle();

    expect(title.exists()).toBe(true);
    expect(title.text()).toBe('Additional Metadata');
  });

  describe.each`
    packageEntity   | visible  | metadata
    ${mavenPackage} | ${true}  | ${'maven_metadatum'}
    ${conanPackage} | ${true}  | ${'conan_metadatum'}
    ${nugetPackage} | ${true}  | ${'nuget_metadatum'}
    ${npmPackage}   | ${false} | ${null}
  `('Component visibility', ({ packageEntity, visible, metadata }) => {
    it(`Is ${visible} that the component markup is visible when the package is ${packageEntity.package_type}`, () => {
      mountComponent({ packageEntity });

      expect(findTitle().exists()).toBe(visible);
      expect(findMainArea().exists()).toBe(visible);
    });

    it(`The component is hidden if ${metadata} is missing`, () => {
      mountComponent({ packageEntity: { ...packageEntity, [metadata]: null } });

      expect(findTitle().exists()).toBe(false);
      expect(findMainArea().exists()).toBe(false);
    });
  });

  describe('nuget metadata', () => {
    beforeEach(() => {
      mountComponent({ packageEntity: nugetPackage });
    });

    it.each`
      name         | finderFunction      | text                                                | link             | icon
      ${'source'}  | ${findNugetSource}  | ${'Source project located at project-foo-url'}      | ${'project_url'} | ${'project'}
      ${'license'} | ${findNugetLicense} | ${'License information located at license-foo-url'} | ${'license_url'} | ${'license'}
    `('$name element', ({ finderFunction, text, link, icon }) => {
      const element = finderFunction();
      expect(element.exists()).toBe(true);
      expect(element.text()).toBe(text);
      expect(element.props('icon')).toBe(icon);
      expect(findElementLink(element).attributes('href')).toBe(nugetPackage.nuget_metadatum[link]);
    });
  });

  describe('conan metadata', () => {
    beforeEach(() => {
      mountComponent({ packageEntity: conanPackage });
    });

    it.each`
      name        | finderFunction     | text                                                        | icon
      ${'recipe'} | ${findConanRecipe} | ${'Recipe: conan-package/1.0.0@conan+conan-package/stable'} | ${'information-o'}
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
      name       | finderFunction    | text                         | icon
      ${'app'}   | ${findMavenApp}   | ${'App name: test-app'}      | ${'information-o'}
      ${'group'} | ${findMavenGroup} | ${'App group: com.test.app'} | ${'information-o'}
    `('$name element', ({ finderFunction, text, icon }) => {
      const element = finderFunction();
      expect(element.exists()).toBe(true);
      expect(element.text()).toBe(text);
      expect(element.props('icon')).toBe(icon);
    });
  });
});
