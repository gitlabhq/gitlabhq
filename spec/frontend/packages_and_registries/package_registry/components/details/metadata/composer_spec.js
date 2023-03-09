import { GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { composerMetadata } from 'jest/packages_and_registries/package_registry/mock_data';
import component from '~/packages_and_registries/package_registry/components/details/metadata/composer.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import DetailsRow from '~/vue_shared/components/registry/details_row.vue';

describe('Composer Metadata', () => {
  let wrapper;

  const mountComponent = () => {
    wrapper = shallowMountExtended(component, {
      propsData: { packageMetadata: composerMetadata() },
      stubs: {
        DetailsRow,
        GlSprintf,
      },
    });
  };

  const findComposerTargetSha = () => wrapper.findByTestId('composer-target-sha');
  const findComposerTargetShaCopyButton = () => wrapper.findComponent(ClipboardButton);
  const findComposerJson = () => wrapper.findByTestId('composer-json');

  beforeEach(() => {
    mountComponent();
  });

  it.each`
    name               | finderFunction           | text                                                      | icon
    ${'target-sha'}    | ${findComposerTargetSha} | ${'Target SHA: b83d6e391c22777fca1ed3012fce84f633d7fed0'} | ${'information-o'}
    ${'composer-json'} | ${findComposerJson}      | ${'Composer.json with license: MIT and version: 1.0.0'}   | ${'information-o'}
  `('$name element', ({ finderFunction, text, icon }) => {
    const element = finderFunction();
    expect(element.exists()).toBe(true);
    expect(element.text()).toBe(text);
    expect(element.props('icon')).toBe(icon);
  });

  it('target-sha has a copy button', () => {
    expect(findComposerTargetShaCopyButton().exists()).toBe(true);
    expect(findComposerTargetShaCopyButton().props()).toMatchObject({
      text: 'b83d6e391c22777fca1ed3012fce84f633d7fed0',
      title: 'Copy target SHA',
    });
  });
});
