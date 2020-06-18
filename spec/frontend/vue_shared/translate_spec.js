import { mount, createLocalVue } from '@vue/test-utils';
import locale from '~/locale';
import Translate from '~/vue_shared/translate';

const localVue = createLocalVue();
localVue.use(Translate);

describe('Vue translate filter', () => {
  const createTranslationMock = (key, ...translations) => {
    locale.textdomain('app');

    locale.options.locale_data = {
      app: {
        '': {
          domain: 'app',
          lang: 'vo',
          plural_forms: 'nplurals=2; plural=(n != 1);',
        },
        [key]: translations,
      },
    };
  };

  it('translate singular text (`__`)', () => {
    const key = 'singular';
    const translation = 'singular_translated';
    createTranslationMock(key, translation);

    const wrapper = mount(
      {
        template: `
          <span>
            {{ __('${key}') }}
          </span>
        `,
      },
      { localVue },
    );

    expect(wrapper.text()).toBe(translation);
  });

  it('translate plural text (`n__`) without any substituting text', () => {
    const key = 'plural';
    const translationPlural = 'plural_multiple translation';
    createTranslationMock(key, 'plural_singular translation', translationPlural);

    const wrapper = mount(
      {
        template: `
          <span>
            {{ n__('${key}', 'plurals', 2) }}
          </span>
        `,
      },
      { localVue },
    );

    expect(wrapper.text()).toBe(translationPlural);
  });

  describe('translate plural text (`n__`) with substituting %d', () => {
    const key = '%d day';

    beforeEach(() => {
      createTranslationMock(key, '%d singular translated', '%d plural translated');
    });

    it('and n === 1', () => {
      const wrapper = mount(
        {
          template: `
            <span>
              {{ n__('${key}', '%d days', 1) }}
            </span>
          `,
        },
        { localVue },
      );

      expect(wrapper.text()).toBe('1 singular translated');
    });

    it('and n > 1', () => {
      const wrapper = mount(
        {
          template: `
            <span>
              {{ n__('${key}', '%d days', 2) }}
            </span>
          `,
        },
        { localVue },
      );

      expect(wrapper.text()).toBe('2 plural translated');
    });
  });

  describe('translates text with context `s__`', () => {
    const key = 'Context|Foobar';
    const translation = 'Context|Foobar translated';
    const expectation = 'Foobar translated';

    beforeEach(() => {
      createTranslationMock(key, translation);
    });

    it('and using two parameters', () => {
      const wrapper = mount(
        {
          template: `
            <span>
              {{ s__('Context', 'Foobar') }}
            </span>
          `,
        },
        { localVue },
      );

      expect(wrapper.text()).toBe(expectation);
    });

    it('and using the pipe syntax', () => {
      const wrapper = mount(
        {
          template: `
            <span>
              {{ s__('${key}') }}
            </span>
          `,
        },
        { localVue },
      );

      expect(wrapper.text()).toBe(expectation);
    });
  });

  it('translate multi line text', () => {
    const translation = 'multiline string translated';
    createTranslationMock('multiline string', translation);

    const wrapper = mount(
      {
        template: `
          <span>
            {{ __(\`
            multiline
            string
            \`) }}
          </span>
        `,
      },
      { localVue },
    );

    expect(wrapper.text()).toBe(translation);
  });

  it('translate pluralized multi line text', () => {
    const translation = 'multiline string plural';

    createTranslationMock('multiline string', 'multiline string singular', translation);

    const wrapper = mount(
      {
        template: `
          <span>
            {{ n__(
            \`
            multiline
            string
            \`,
            \`
            multiline
            strings
            \`,
            2
            ) }}
          </span>
        `,
      },
      { localVue },
    );

    expect(wrapper.text()).toBe(translation);
  });

  it('translate pluralized multi line text with context', () => {
    const translation = 'multiline string with context';

    createTranslationMock('Context| multiline string', translation);

    const wrapper = mount(
      {
        template: `
          <span>
            {{ s__(
            \`
            Context|
            multiline
            string
            \`
            ) }}
          </span>
        `,
      },
      { localVue },
    );

    expect(wrapper.text()).toBe(translation);
  });
});
