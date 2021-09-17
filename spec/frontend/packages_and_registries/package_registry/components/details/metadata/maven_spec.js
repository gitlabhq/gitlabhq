import { GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import {
  mavenMetadata,
  packageData,
} from 'jest/packages_and_registries/package_registry/mock_data';
import component from '~/packages_and_registries/package_registry/components/details/metadata/maven.vue';
import { PACKAGE_TYPE_MAVEN } from '~/packages_and_registries/package_registry/constants';
import DetailsRow from '~/vue_shared/components/registry/details_row.vue';

const mavenPackage = { packageType: PACKAGE_TYPE_MAVEN, metadata: mavenMetadata() };

describe('Maven Metadata', () => {
  let wrapper;

  const mountComponent = () => {
    wrapper = shallowMountExtended(component, {
      propsData: {
        packageEntity: {
          ...packageData(mavenPackage),
        },
      },
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

  const findMavenApp = () => wrapper.findByTestId('maven-app');
  const findMavenGroup = () => wrapper.findByTestId('maven-group');

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
