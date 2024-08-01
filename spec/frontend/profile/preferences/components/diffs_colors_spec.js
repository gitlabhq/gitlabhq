import { shallowMount } from '@vue/test-utils';
import ColorPicker from '~/vue_shared/components/color_picker/color_picker.vue';
import DiffsColors from '~/profile/preferences/components/diffs_colors.vue';
import DiffsColorsPreview from '~/profile/preferences/components/diffs_colors_preview.vue';
import * as CssUtils from '~/lib/utils/css_utils';

describe('DiffsColors component', () => {
  let wrapper;

  const defaultInjectedProps = {
    addition: '#00ff00',
    deletion: '#ff0000',
  };

  const initialSuggestedColors = {
    '#d99530': 'Orange',
    '#1f75cb': 'Blue',
  };

  const findColorPickers = () => wrapper.findAllComponents(ColorPicker);

  function createComponent(provide = {}) {
    wrapper = shallowMount(DiffsColors, {
      provide: {
        ...defaultInjectedProps,
        ...provide,
      },
    });
  }

  it('mounts', () => {
    createComponent();

    expect(wrapper.exists()).toBe(true);
  });

  describe('preview', () => {
    it('should render preview', () => {
      createComponent();

      expect(wrapper.findComponent(DiffsColorsPreview).exists()).toBe(true);
    });

    it('should set preview classes', () => {
      createComponent();

      expect(wrapper.attributes('class')).toBe(
        'diff-custom-addition-color diff-custom-deletion-color',
      );
    });

    it.each([
      [{ addition: null }, 'diff-custom-deletion-color'],
      [{ deletion: null }, 'diff-custom-addition-color'],
    ])('should not set preview class if color not set', (provide, expectedClass) => {
      createComponent(provide);

      expect(wrapper.attributes('class')).toBe(expectedClass);
    });

    it.each([
      [
        {},
        '--diff-deletion-color: rgba(255, 0, 0, 0.2); --diff-addition-color: rgba(0, 255, 0, 0.2);',
      ],
      [{ addition: null }, '--diff-deletion-color: rgba(255, 0, 0, 0.2);'],
      [{ deletion: null }, '--diff-addition-color: rgba(0, 255, 0, 0.2);'],
    ])('should set correct CSS variables', (provide, expectedStyle) => {
      createComponent(provide);

      expect(wrapper.attributes('style')).toBe(expectedStyle);
    });
  });

  describe('color pickers', () => {
    it('should render both color pickers', () => {
      createComponent();

      const colorPickers = findColorPickers();

      expect(colorPickers.length).toBe(2);
      expect(colorPickers.at(0).props()).toMatchObject({
        label: 'Color for removed lines',
        value: '#ff0000',
        state: true,
      });
      expect(colorPickers.at(1).props()).toMatchObject({
        label: 'Color for added lines',
        value: '#00ff00',
        state: true,
      });
    });

    describe('suggested colors', () => {
      const suggestedColors = () => findColorPickers().at(0).props('suggestedColors');

      it('contains initial suggested colors', () => {
        createComponent();

        expect(suggestedColors()).toMatchObject(initialSuggestedColors);
      });

      it('contains default diff colors of theme', () => {
        jest.spyOn(CssUtils, 'getCssVariable').mockImplementation((variable) => {
          if (variable === '--default-diff-color-addition') return '#111111';
          if (variable === '--default-diff-color-deletion') return '#222222';
          return '#000000';
        });

        createComponent();

        expect(suggestedColors()).toMatchObject({
          '#111111': 'Default addition color',
          '#222222': 'Default removal color',
        });
      });

      it('contains current diff colors if set', () => {
        createComponent();

        expect(suggestedColors()).toMatchObject({
          [defaultInjectedProps.addition]: 'Current addition color',
          [defaultInjectedProps.deletion]: 'Current removal color',
        });
      });

      it.each([
        [{ addition: null }, 'Current removal color', 'Current addition color'],
        [{ deletion: null }, 'Current addition color', 'Current removal color'],
      ])(
        'does not contain current diff color if not set %p',
        (provide, expectedToContain, expectNotToContain) => {
          createComponent(provide);

          const suggestedColorsLabels = Object.values(suggestedColors());
          expect(suggestedColorsLabels).toContain(expectedToContain);
          expect(suggestedColorsLabels).not.toContain(expectNotToContain);
        },
      );
    });
  });
});
