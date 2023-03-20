import { GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { nugetMetadata } from 'jest/packages_and_registries/package_registry/mock_data';
import component from '~/packages_and_registries/package_registry/components/details/metadata/nuget.vue';

import DetailsRow from '~/vue_shared/components/registry/details_row.vue';

describe('Nuget Metadata', () => {
  let nugetPackageMetadata = { ...nugetMetadata() };
  let wrapper;

  const mountComponent = (props) => {
    wrapper = shallowMountExtended(component, {
      propsData: { ...props },
      stubs: {
        DetailsRow,
        GlSprintf,
      },
    });
  };

  const findNugetSource = () => wrapper.findByTestId('nuget-source');
  const findNugetLicense = () => wrapper.findByTestId('nuget-license');
  const findElementLink = (container) => container.findComponent(GlLink);

  beforeEach(() => {
    mountComponent({ packageMetadata: nugetPackageMetadata });
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
    expect(findElementLink(element).attributes('href')).toBe(nugetPackageMetadata[link]);
  });

  describe('without source', () => {
    beforeAll(() => {
      nugetPackageMetadata = {
        iconUrl: 'iconUrl',
        licenseUrl: 'licenseUrl',
      };
    });

    it('does not show additional metadata', () => {
      expect(findNugetSource().exists()).toBe(false);
    });
  });

  describe('without license', () => {
    beforeAll(() => {
      nugetPackageMetadata = {
        iconUrl: 'iconUrl',
        projectUrl: 'projectUrl',
      };
    });

    it('does not show additional metadata', () => {
      expect(findNugetLicense().exists()).toBe(false);
    });
  });
});
