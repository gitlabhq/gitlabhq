import { GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { pypiMetadata } from 'jest/packages_and_registries/package_registry/mock_data';
import component from '~/packages_and_registries/package_registry/components/details/metadata/pypi.vue';

import DetailsRow from '~/vue_shared/components/registry/details_row.vue';

describe('Package Additional Metadata', () => {
  let wrapper;

  const mountComponent = () => {
    wrapper = shallowMountExtended(component, {
      propsData: {
        packageMetadata: pypiMetadata(),
      },
      stubs: {
        DetailsRow,
        GlSprintf,
      },
    });
  };

  const findPypiRequiredPython = () => wrapper.findByTestId('pypi-required-python');

  beforeEach(() => {
    mountComponent();
  });

  it.each`
    name                      | finderFunction            | text                        | icon
    ${'pypi-required-python'} | ${findPypiRequiredPython} | ${'Required Python: 1.0.0'} | ${'information-o'}
  `('$name element', ({ finderFunction, text, icon }) => {
    const element = finderFunction();
    expect(element.exists()).toBe(true);
    expect(element.text()).toBe(text);
    expect(element.props('icon')).toBe(icon);
  });
});
