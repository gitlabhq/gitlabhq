import { GlFormRadio, GlIcon, GlFormRadioGroup, GlLink } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import SnippetVisibilityEdit from '~/snippets/components/snippet_visibility_edit.vue';
import {
  SNIPPET_VISIBILITY,
  SNIPPET_VISIBILITY_PRIVATE,
  SNIPPET_VISIBILITY_INTERNAL,
  SNIPPET_VISIBILITY_PUBLIC,
  SNIPPET_LEVELS_RESTRICTED,
  SNIPPET_LEVELS_DISABLED,
} from '~/snippets/constants';

describe('Snippet Visibility Edit component', () => {
  let wrapper;
  const defaultHelpLink = '/foo/bar';
  const defaultVisibilityLevel = 'private';

  function createComponent({
    propsData = {},
    visibilityLevels = [0, 10, 20],
    multipleLevelsRestricted = false,
    deep = false,
  } = {}) {
    const method = deep ? mount : shallowMount;

    wrapper = method.call(this, SnippetVisibilityEdit, {
      propsData: {
        helpLink: defaultHelpLink,
        isProjectSnippet: false,
        value: defaultVisibilityLevel,
        ...propsData,
      },
      provide: {
        visibilityLevels,
        multipleLevelsRestricted,
      },
    });
  }

  const findLink = () => wrapper.find('label').find(GlLink);
  const findRadios = () => wrapper.find(GlFormRadioGroup).findAll(GlFormRadio);
  const findRadiosData = () =>
    findRadios().wrappers.map((x) => {
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

    it('renders label help link', () => {
      createComponent();

      expect(findLink().attributes('href')).toBe(defaultHelpLink);
    });

    it('when helpLink is not defined, does not render label help link', () => {
      createComponent({ propsData: { helpLink: null } });

      expect(findLink().exists()).toBe(false);
    });

    describe('Visibility options', () => {
      const findRestrictedInfo = () => wrapper.find('[data-testid="restricted-levels-info"]');
      const RESULTING_OPTIONS = {
        0: {
          value: SNIPPET_VISIBILITY_PRIVATE,
          icon: SNIPPET_VISIBILITY.private.icon,
          text: SNIPPET_VISIBILITY.private.label,
          description: SNIPPET_VISIBILITY.private.description,
        },
        10: {
          value: SNIPPET_VISIBILITY_INTERNAL,
          icon: SNIPPET_VISIBILITY.internal.icon,
          text: SNIPPET_VISIBILITY.internal.label,
          description: SNIPPET_VISIBILITY.internal.description,
        },
        20: {
          value: SNIPPET_VISIBILITY_PUBLIC,
          icon: SNIPPET_VISIBILITY.public.icon,
          text: SNIPPET_VISIBILITY.public.label,
          description: SNIPPET_VISIBILITY.public.description,
        },
      };

      it.each`
        levels         | resultOptions
        ${''}          | ${[]}
        ${[]}          | ${[]}
        ${[0]}         | ${[RESULTING_OPTIONS[0]]}
        ${[0, 10]}     | ${[RESULTING_OPTIONS[0], RESULTING_OPTIONS[10]]}
        ${[0, 10, 20]} | ${[RESULTING_OPTIONS[0], RESULTING_OPTIONS[10], RESULTING_OPTIONS[20]]}
        ${[0, 20]}     | ${[RESULTING_OPTIONS[0], RESULTING_OPTIONS[20]]}
        ${[10, 20]}    | ${[RESULTING_OPTIONS[10], RESULTING_OPTIONS[20]]}
      `('renders correct visibility options for $levels', ({ levels, resultOptions }) => {
        createComponent({ visibilityLevels: levels, deep: true });
        expect(findRadiosData()).toEqual(resultOptions);
      });

      it.each`
        levels         | levelsRestricted | resultText
        ${[]}          | ${false}         | ${SNIPPET_LEVELS_DISABLED}
        ${[]}          | ${true}          | ${SNIPPET_LEVELS_DISABLED}
        ${[0]}         | ${true}          | ${SNIPPET_LEVELS_RESTRICTED}
        ${[0]}         | ${false}         | ${''}
        ${[0, 10, 20]} | ${false}         | ${''}
      `(
        'renders correct information about restricted visibility levels for $levels',
        ({ levels, levelsRestricted, resultText }) => {
          createComponent({
            visibilityLevels: levels,
            multipleLevelsRestricted: levelsRestricted,
          });
          expect(findRestrictedInfo().text()).toBe(resultText);
        },
      );

      it('when project snippet, renders special private description', () => {
        createComponent({ propsData: { isProjectSnippet: true }, deep: true });

        expect(findRadiosData()[0]).toEqual({
          value: SNIPPET_VISIBILITY_PRIVATE,
          icon: SNIPPET_VISIBILITY.private.icon,
          text: SNIPPET_VISIBILITY.private.label,
          description: SNIPPET_VISIBILITY.private.description_project,
        });
      });
    });
  });

  describe('functionality', () => {
    it('pre-selects correct option in the list', () => {
      const value = SNIPPET_VISIBILITY_INTERNAL;

      createComponent({ propsData: { value } });

      expect(wrapper.find(GlFormRadioGroup).attributes('checked')).toBe(value);
    });
  });
});
