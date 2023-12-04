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
  const findPypiAuthorEmail = () => wrapper.findByTestId('pypi-author-email');
  const findPypiSummary = () => wrapper.findByTestId('pypi-summary');
  const findPypiKeywords = () => wrapper.findByTestId('pypi-keywords');

  beforeEach(() => {
    mountComponent();
  });

  it.each`
    name                      | finderFunction            | text                                                      | icon
    ${'pypi-required-python'} | ${findPypiRequiredPython} | ${'Required Python: 1.0.0'}                               | ${'information-o'}
    ${'pypi-author-email'}    | ${findPypiAuthorEmail}    | ${'Author email: "C. Schultz" <cschultz@example.com>'}    | ${'mail'}
    ${'pypi-summary'}         | ${findPypiSummary}        | ${'Summary: A module for collecting votes from beagles.'} | ${'doc-text'}
    ${'pypi-keywords'}        | ${findPypiKeywords}       | ${'Keywords: dog,puppy,voting,election'}                  | ${'doc-text'}
  `('$name element', ({ finderFunction, text, icon }) => {
    const element = finderFunction();
    expect(element.exists()).toBe(true);
    expect(element.text()).toBe(text);
    expect(element.props('icon')).toBe(icon);
  });
});
