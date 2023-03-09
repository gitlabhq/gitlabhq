import { GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { mavenMetadata } from 'jest/packages_and_registries/package_registry/mock_data';
import component from '~/packages_and_registries/package_registry/components/details/metadata/maven.vue';
import DetailsRow from '~/vue_shared/components/registry/details_row.vue';

describe('Maven Metadata', () => {
  let wrapper;

  const mountComponent = () => {
    wrapper = shallowMountExtended(component, {
      propsData: {
        packageMetadata: mavenMetadata(),
      },
      stubs: {
        DetailsRow,
        GlSprintf,
      },
    });
  };

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
