import {
  embedDimensions,
  embedMinWidth,
  embedStyle,
  getIframeStyle,
  getPlaceholderStyles,
} from '~/behaviors/markdown/external_content';

describe('external content sizing', () => {
  describe('embedStyle', () => {
    it('keeps the embed within its container, with a floor that yields to it', () => {
      expect(embedStyle).toEqual({ maxWidth: '100%', minWidth: 'min(17rem, 100%)' });
    });
  });

  describe('embedMinWidth', () => {
    beforeEach(() => {
      document.documentElement.style.fontSize = '18px';
    });

    afterEach(() => {
      document.documentElement.style.fontSize = '';
    });

    describe('when the available width exceeds the floor', () => {
      it('is the floor, scaled by the root font size', () => {
        expect(embedMinWidth(800)).toBe(306);
      });
    });

    describe('when the available width is below the floor', () => {
      it('is the available width', () => {
        expect(embedMinWidth(200)).toBe(200);
      });
    });
  });

  describe('embedDimensions', () => {
    describe('when no dimensions are given', () => {
      it('defaults to 560 by 315', () => {
        expect(embedDimensions(null, null)).toEqual({ width: '560', height: '315' });
      });
    });

    describe.each`
      width    | height
      ${'50%'} | ${null}
      ${null}  | ${'200'}
      ${'10'}  | ${'10'}
    `('when a dimension is given (width=$width, height=$height)', ({ width, height }) => {
      it('keeps the given dimensions', () => {
        expect(embedDimensions(width, height)).toEqual({ width, height });
      });
    });
  });

  describe('getIframeStyle', () => {
    describe.each`
      width    | height
      ${'560'} | ${null}
      ${null}  | ${'315'}
    `('when only one dimension is given (width=$width, height=$height)', ({ width, height }) => {
      it('caps the width and height without an aspect ratio', () => {
        expect(getIframeStyle(width, height)).toEqual({ maxHeight: '80vh', maxWidth: '100%' });
      });
    });

    describe.each`
      width      | height
      ${'560'}   | ${'315'}
      ${'560px'} | ${'315px'}
      ${'560'}   | ${'315px'}
      ${560}     | ${315}
    `('when both dimensions are in pixels (width=$width, height=$height)', ({ width, height }) => {
      it('keeps the aspect ratio and caps the height to the requested height', () => {
        expect(getIframeStyle(width, height)).toEqual({
          aspectRatio: '560 / 315',
          height: 'auto',
          maxHeight: 'min(80vh, 315px)',
          maxWidth: '100%',
        });
      });
    });

    describe.each`
      width    | height
      ${'50%'} | ${'315'}
      ${'560'} | ${'50%'}
      ${'50%'} | ${'50%'}
    `(
      'when either dimension is a percentage (width=$width, height=$height)',
      ({ width, height }) => {
        it('caps the width and height without an aspect ratio', () => {
          expect(getIframeStyle(width, height)).toEqual({ maxHeight: '80vh', maxWidth: '100%' });
        });
      },
    );
  });

  describe('getPlaceholderStyles', () => {
    describe('when both dimensions are in pixels', () => {
      it('sizes the box by width and gives the spacer the aspect ratio', () => {
        expect(getPlaceholderStyles('560', '315px')).toEqual({
          box: { width: '560px', maxWidth: '100%' },
          spacer: { aspectRatio: '560 / 315', maxHeight: 'min(80vh, 315px)' },
        });
      });
    });

    describe('when either dimension is not in pixels', () => {
      it('holds the box to at least the requested height without an aspect ratio', () => {
        expect(getPlaceholderStyles('50%', '200')).toEqual({
          box: { width: '50%', maxWidth: '100%', minHeight: '200px' },
          spacer: { aspectRatio: undefined, maxHeight: '80vh' },
        });
      });
    });

    describe('when only the width is given', () => {
      it('leaves the height to the content', () => {
        expect(getPlaceholderStyles('10', null)).toEqual({
          box: { width: '10px', maxWidth: '100%', minHeight: null },
          spacer: { aspectRatio: undefined, maxHeight: '80vh' },
        });
      });
    });
  });
});
