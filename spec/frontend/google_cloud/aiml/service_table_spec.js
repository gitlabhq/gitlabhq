import { GlTable } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import ServiceTable from '~/google_cloud/aiml/service_table.vue';

describe('google_cloud/aiml/service_table', () => {
  let wrapper;

  const findTable = () => wrapper.findComponent(GlTable);

  beforeEach(() => {
    const propsData = {
      visionAiUrl: '#url-vision-ai',
      languageAiUrl: '#url-language-ai',
      translationAiUrl: '#url-translate-ai',
    };
    wrapper = mountExtended(ServiceTable, { propsData });
  });

  it('should contain a table', () => {
    expect(findTable().exists()).toBe(true);
  });

  it.each`
    name                         | testId                          | url
    ${'key-vision-ai'}           | ${'button-vision-ai'}           | ${'#url-vision-ai'}
    ${'key-natural-language-ai'} | ${'button-natural-language-ai'} | ${'#url-language-ai'}
    ${'key-translation-ai'}      | ${'button-translation-ai'}      | ${'#url-translate-ai'}
  `('renders $name button with correct url', ({ testId, url }) => {
    const button = wrapper.findByTestId(testId);

    expect(button.exists()).toBe(true);
    expect(button.attributes('href')).toBe(url);
  });
});
