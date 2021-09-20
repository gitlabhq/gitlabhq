import { GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { packageData, pypiMetadata } from 'jest/packages_and_registries/package_registry/mock_data';
import component from '~/packages_and_registries/package_registry/components/details/metadata/pypi.vue';
import { PACKAGE_TYPE_PYPI } from '~/packages_and_registries/package_registry/constants';

import DetailsRow from '~/vue_shared/components/registry/details_row.vue';

const pypiPackage = { packageType: PACKAGE_TYPE_PYPI, metadata: pypiMetadata() };

describe('Package Additional Metadata', () => {
  let wrapper;

  const mountComponent = () => {
    wrapper = shallowMountExtended(component, {
      propsData: {
        packageEntity: {
          ...packageData(pypiPackage),
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
