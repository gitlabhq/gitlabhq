import Vue from 'vue';
import htmlOutput from '~/notebook/cells/output/html.vue';
import sanitizeTests from './html_sanitize_fixtures';

describe('html output cell', () => {
  function createComponent(rawCode) {
    const Component = Vue.extend(htmlOutput);

    return new Component({
      propsData: {
        rawCode,
        count: 0,
        index: 0,
      },
    }).$mount();
  }

  it.each(sanitizeTests)('sanitizes output for: %p', (name, { input, output }) => {
    const vm = createComponent(input);
    const outputEl = [...vm.$el.querySelectorAll('div')].pop();

    expect(outputEl.innerHTML).toEqual(output);

    vm.$destroy();
  });
});
