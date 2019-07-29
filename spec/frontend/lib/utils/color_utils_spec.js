import { textColorForBackground, hexToRgb } from '~/lib/utils/color_utils';

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
});
