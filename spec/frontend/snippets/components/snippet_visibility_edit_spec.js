import SnippetVisibilityEdit from '~/snippets/components/snippet_visibility_edit.vue';
import { GlFormRadio, GlIcon, GlFormRadioGroup, GlLink } from '@gitlab/ui';
import {
  SNIPPET_VISIBILITY,
  SNIPPET_VISIBILITY_PRIVATE,
  SNIPPET_VISIBILITY_INTERNAL,
  SNIPPET_VISIBILITY_PUBLIC,
} from '~/snippets/constants';
import { mount, shallowMount } from '@vue/test-utils';

describe('Snippet Visibility Edit component', () => {
  let wrapper;
  const defaultHelpLink = '/foo/bar';
  const defaultVisibilityLevel = 'private';

  function createComponent(propsData = {}, deep = false) {
    const method = deep ? mount : shallowMount;
    wrapper = method.call(this, SnippetVisibilityEdit, {
      propsData: {
        helpLink: defaultHelpLink,
        isProjectSnippet: false,
        value: defaultVisibilityLevel,
        ...propsData,
      },
    });
  }

  const findLabel = () => wrapper.find('label');
  const findRadios = () => wrapper.find(GlFormRadioGroup).findAll(GlFormRadio);
  const findRadiosData = () =>
    findRadios().wrappers.map(x => {
      return {
        value: x.find('input').attributes('value'),
        icon: x.find(GlIcon).props('name'),
        description: x.find('.help-text').text(),
        text: x.find('.js-visibility-option').text(),
      };
    });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('rendering', () => {
    it('matches the snapshot', () => {
      createComponent();
      expect(wrapper.element).toMatchSnapshot();
    });

    it('renders visibility options', () => {
      createComponent({}, true);

      expect(findRadiosData()).toEqual([
        {
          value: SNIPPET_VISIBILITY_PRIVATE,
          icon: SNIPPET_VISIBILITY.private.icon,
          text: SNIPPET_VISIBILITY.private.label,
          description: SNIPPET_VISIBILITY.private.description,
        },
        {
          value: SNIPPET_VISIBILITY_INTERNAL,
          icon: SNIPPET_VISIBILITY.internal.icon,
          text: SNIPPET_VISIBILITY.internal.label,
          description: SNIPPET_VISIBILITY.internal.description,
        },
        {
          value: SNIPPET_VISIBILITY_PUBLIC,
          icon: SNIPPET_VISIBILITY.public.icon,
          text: SNIPPET_VISIBILITY.public.label,
          description: SNIPPET_VISIBILITY.public.description,
        },
      ]);
    });

    it('when project snippet, renders special private description', () => {
      createComponent({ isProjectSnippet: true }, true);

      expect(findRadiosData()[0]).toEqual({
        value: SNIPPET_VISIBILITY_PRIVATE,
        icon: SNIPPET_VISIBILITY.private.icon,
        text: SNIPPET_VISIBILITY.private.label,
        description: SNIPPET_VISIBILITY.private.description_project,
      });
    });

    it('renders label help link', () => {
      createComponent();

      expect(
        findLabel()
          .find(GlLink)
          .attributes('href'),
      ).toBe(defaultHelpLink);
    });

    it('when helpLink is not defined, does not render label help link', () => {
      createComponent({ helpLink: null });

      expect(findLabel().contains(GlLink)).toBe(false);
    });
  });

  describe('functionality', () => {
    it('pre-selects correct option in the list', () => {
      const value = SNIPPET_VISIBILITY_INTERNAL;

      createComponent({ value });

      expect(wrapper.find(GlFormRadioGroup).attributes('checked')).toBe(value);
    });
  });
});
