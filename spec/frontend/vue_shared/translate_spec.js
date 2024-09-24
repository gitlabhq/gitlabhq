import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import locale from '~/locale';
import Translate from '~/vue_shared/translate';
import Component from './translate_spec.vue';

Vue.use(Translate);

describe('Vue translate filter', () => {
  let oldDomain;
  let oldData;

  beforeAll(() => {
    oldDomain = locale.textdomain();
    oldData = locale.options.locale_data;

    locale.textdomain('app');
    locale.options.locale_data = {
      app: {
        '': {
          domain: 'app',
          lang: 'vo',
          plural_forms: 'nplurals=2; plural=(n != 1);',
        },
        singular: ['singular_translated'],
        plural: ['plural_singular translation', 'plural_multiple translation'],
        '%d day': ['%d singular translated', '%d plural translated'],
        'Context|Foobar': ['Context|Foobar translated'],
        'multiline string': ['multiline string translated'],
        'multiline plural': ['multiline string singular', 'multiline string plural'],
        'Context| multiline string': ['multiline string with context'],
      },
    };
  });

  afterAll(() => {
    locale.textdomain(oldDomain);
    locale.options.locale_data = oldData;
  });

  it('works properly', async () => {
    const wrapper = await shallowMount(Component);

    const { wrappers } = wrapper.findAll('span');

    // Just to ensure that the rendering actually worked;
    expect(wrappers.length).toBe(10);

    for (const span of wrappers) {
      expect(span.text().trim()).toBe(span.attributes()['data-expected']);
    }
  });
});
