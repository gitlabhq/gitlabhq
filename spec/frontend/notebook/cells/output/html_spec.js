import { mount } from '@vue/test-utils';
import HtmlOutput from '~/notebook/cells/output/html.vue';
import sanitizeTests from './html_sanitize_fixtures';

describe('html output cell', () => {
  function createComponent(rawCode) {
    return mount(HtmlOutput, {
      propsData: {
        rawCode,
        count: 0,
        index: 0,
      },
    });
  }

  it.each(sanitizeTests)('sanitizes output for: %p', (name, { input, output }) => {
    const vm = createComponent(input);

    expect(vm.html()).toContain(output);
  });
});
