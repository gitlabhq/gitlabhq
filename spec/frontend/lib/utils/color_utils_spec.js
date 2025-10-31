import {
  isValidColorExpression,
  validateHexColor,
  darkModeEnabled,
  getAdaptiveStatusColor,
  gradientStyle,
} from '~/lib/utils/color_utils';
import { getSystemColorScheme } from '~/lib/utils/css_utils';

jest.mock('~/lib/utils/css_utils');

describe('Color utils', () => {
  describe('Validate hex color', () => {
    it.each`
      color        | output
      ${undefined} | ${null}
      ${null}      | ${null}
      ${''}        | ${null}
      ${'ABC123'}  | ${false}
      ${'#ZZZ'}    | ${false}
      ${'#FF0'}    | ${true}
      ${'#FF0000'} | ${true}
    `('returns $output when $color is given', ({ color, output }) => {
      expect(validateHexColor(color)).toEqual(output);
    });
  });

  describe('darkModeEnabled', () => {
    it.each`
      page                     | rootClass     | ideTheme           | expected
      ${'ide:index'}           | ${'gl-dark'}  | ${'monokai-light'} | ${false}
      ${'ide:index'}           | ${'ui-light'} | ${'monokai'}       | ${true}
      ${'groups:issues:index'} | ${'ui-light'} | ${'monokai'}       | ${false}
      ${'groups:issues:index'} | ${'gl-dark'}  | ${'monokai-light'} | ${true}
    `(
      'is $expected on $page with $rootClass root class and $ideTheme IDE theme',
      ({ page, rootClass, ideTheme, expected }) => {
        document.documentElement.className = rootClass;
        document.body.outerHTML = `<body data-page="${page}"></body>`;

        window.gon = {
          user_color_scheme: ideTheme,
        };

        expect(darkModeEnabled()).toBe(expected);
      },
    );
  });

  describe('isValidColorExpression', () => {
    it.each`
      colorExpression       | valid    | desc
      ${'#F00'}             | ${true}  | ${'valid'}
      ${'rgba(0,0,0,0)'}    | ${true}  | ${'valid'}
      ${'hsl(540,70%,50%)'} | ${true}  | ${'valid'}
      ${'red'}              | ${true}  | ${'valid'}
      ${'F00'}              | ${false} | ${'invalid'}
      ${'F00'}              | ${false} | ${'invalid'}
      ${'gba(0,0,0,0)'}     | ${false} | ${'invalid'}
      ${'hls(540,70%,50%)'} | ${false} | ${'invalid'}
      ${'hello'}            | ${false} | ${'invalid'}
    `('color expression $colorExpression is $desc', ({ colorExpression, valid }) => {
      expect(isValidColorExpression(colorExpression)).toBe(valid);
    });
  });

  describe('getAdaptiveStatusColor', () => {
    it.each`
      color        | expectedColor
      ${'#995715'} | ${'#D99530'}
      ${'#737278'} | ${'#89888D'}
      ${'#1f75cb'} | ${'#428FDC'}
      ${'#108548'} | ${'#2DA160'}
      ${'#DD2B0E'} | ${'#EC5941'}
    `('returns $expectedColor for $color when dark mode is enabled', ({ color, expectedColor }) => {
      getSystemColorScheme.mockReturnValueOnce('gl-dark');
      expect(getAdaptiveStatusColor(color)).toBe(expectedColor);
    });

    it('returns source color as it is when light mode is enabled', () => {
      getSystemColorScheme.mockReturnValueOnce('gl-light');
      const colors = ['#995715', '#737278', '#1f75cb', '#108548', '#DD2B0E'];

      colors.forEach((color) => {
        expect(getAdaptiveStatusColor(color)).toBe(color);
      });
    });
  });

  describe('gradientStyle', () => {
    it.each`
      color
      ${'#0066cc'}
      ${'rgba(255, 0, 0, 0.5)'}
      ${'var(--gl-brand-color)'}
    `('returns a radial gradient style for $color', ({ color }) => {
      expect(gradientStyle(color)).toEqual({
        background: `radial-gradient(circle at center, white 20%, ${color} 100%)`,
      });
    });
  });
});
