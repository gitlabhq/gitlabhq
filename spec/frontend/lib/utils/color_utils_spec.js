import {
  textColorForBackground,
  hexToRgb,
  validateHexColor,
  darkModeEnabled,
} from '~/lib/utils/color_utils';

describe('Color utils', () => {
  describe('Converting hex code to rgb', () => {
    it('convert hex code to rgb', () => {
      expect(hexToRgb('#000000')).toEqual([0, 0, 0]);
      expect(hexToRgb('#ffffff')).toEqual([255, 255, 255]);
    });

    it('convert short hex code to rgb', () => {
      expect(hexToRgb('#000')).toEqual([0, 0, 0]);
      expect(hexToRgb('#fff')).toEqual([255, 255, 255]);
    });

    it('handle conversion regardless of the characters case', () => {
      expect(hexToRgb('#f0F')).toEqual([255, 0, 255]);
    });
  });

  describe('Getting text color for given background', () => {
    // following tests are being ported from `text_color_for_bg` section in labels_helper_spec.rb
    it('uses light text on dark backgrounds', () => {
      expect(textColorForBackground('#222E2E')).toEqual('#FFFFFF');
    });

    it('uses dark text on light backgrounds', () => {
      expect(textColorForBackground('#EEEEEE')).toEqual('#333333');
    });

    it('supports RGB triplets', () => {
      expect(textColorForBackground('#FFF')).toEqual('#333333');
      expect(textColorForBackground('#000')).toEqual('#FFFFFF');
    });
  });

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
      page                     | bodyClass     | ideTheme           | expected
      ${'ide:index'}           | ${'gl-dark'}  | ${'monokai-light'} | ${false}
      ${'ide:index'}           | ${'ui-light'} | ${'monokai'}       | ${true}
      ${'groups:issues:index'} | ${'ui-light'} | ${'monokai'}       | ${false}
      ${'groups:issues:index'} | ${'gl-dark'}  | ${'monokai-light'} | ${true}
    `(
      'is $expected on $page with $bodyClass body class and $ideTheme IDE theme',
      async ({ page, bodyClass, ideTheme, expected }) => {
        document.body.outerHTML = `<body class="${bodyClass}" data-page="${page}"></body>`;
        window.gon = {
          user_color_scheme: ideTheme,
        };

        expect(darkModeEnabled()).toBe(expected);
      },
    );
  });
});
