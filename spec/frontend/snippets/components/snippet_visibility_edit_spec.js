import SnippetVisibilityEdit from '~/snippets/components/snippet_visibility_edit.vue';
import { GlFormRadio } from '@gitlab/ui';
import { SNIPPET_VISIBILITY } from '~/snippets/constants';
import { mount, shallowMount } from '@vue/test-utils';

describe('Snippet Visibility Edit component', () => {
  let wrapper;
  let radios;
  const defaultHelpLink = '/foo/bar';
  const defaultVisibilityLevel = '0';

  function findElements(sel) {
    return wrapper.findAll(sel);
  }

  function createComponent(
    {
      helpLink = defaultHelpLink,
      isProjectSnippet = false,
      visibilityLevel = defaultVisibilityLevel,
    } = {},
    deep = false,
  ) {
    const method = deep ? mount : shallowMount;
    wrapper = method.call(this, SnippetVisibilityEdit, {
      propsData: {
        helpLink,
        isProjectSnippet,
        visibilityLevel,
      },
    });
    radios = findElements(GlFormRadio);
  }

  afterEach(() => {
    wrapper.destroy();
  });

  describe('rendering', () => {
    it('matches the snapshot', () => {
      createComponent();
      expect(wrapper.element).toMatchSnapshot();
    });

    it.each`
      label                                | value
      ${SNIPPET_VISIBILITY.private.label}  | ${`0`}
      ${SNIPPET_VISIBILITY.internal.label} | ${`1`}
      ${SNIPPET_VISIBILITY.public.label}   | ${`2`}
    `('should render correct $label label', ({ label, value }) => {
      createComponent();
      const radio = radios.at(parseInt(value, 10));

      expect(radio.attributes('value')).toBe(value);
      expect(radio.text()).toContain(label);
    });

    describe('rendered help-text', () => {
      it.each`
        description                                | value  | label
        ${SNIPPET_VISIBILITY.private.description}  | ${`0`} | ${SNIPPET_VISIBILITY.private.label}
        ${SNIPPET_VISIBILITY.internal.description} | ${`1`} | ${SNIPPET_VISIBILITY.internal.label}
        ${SNIPPET_VISIBILITY.public.description}   | ${`2`} | ${SNIPPET_VISIBILITY.public.label}
      `('should render correct $label description', ({ description, value }) => {
        createComponent({}, true);

        const help = findElements('.help-text').at(parseInt(value, 10));

        expect(help.text()).toBe(description);
      });

      it('renders correct Private description for a project snippet', () => {
        createComponent({ isProjectSnippet: true }, true);

        const helpText = findElements('.help-text')
          .at(0)
          .text();

        expect(helpText).not.toContain(SNIPPET_VISIBILITY.private.description);
        expect(helpText).toBe(SNIPPET_VISIBILITY.private.description_project);
      });
    });
  });

  describe('functionality', () => {
    it('pre-selects correct option in the list', () => {
      const pos = 1;

      createComponent({ visibilityLevel: `${pos}` }, true);
      const radio = radios.at(pos);
      expect(radio.find('input[type="radio"]').element.checked).toBe(true);
    });
  });
});
