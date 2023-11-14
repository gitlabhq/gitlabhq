import { isValidColorExpression, validateHexColor, darkModeEnabled } from '~/lib/utils/color_utils';

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
});
