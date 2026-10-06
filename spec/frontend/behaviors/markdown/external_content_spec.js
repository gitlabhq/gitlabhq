import {
  embedMinWidth,
  embedStyle,
  getIframeClasses,
  getIframeStyle,
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

  describe('getIframeStyle', () => {
    describe('when no dimensions are given', () => {
      it('only caps the height', () => {
        expect(getIframeStyle(null, null)).toEqual({ maxHeight: '80vh' });
      });
    });

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

  describe('getIframeClasses', () => {
    describe('when no dimensions are given', () => {
      it('fills the container', () => {
        expect(getIframeClasses(null, null)).toEqual([
          'gl-min-w-full gl-border-none',
          { 'gl-inset-0 gl-h-full gl-w-full': true },
        ]);
      });
    });

    describe.each`
      width    | height
      ${'560'} | ${null}
      ${null}  | ${'315'}
      ${'560'} | ${'315'}
    `('when a dimension is given (width=$width, height=$height)', ({ width, height }) => {
      it('does not fill the container', () => {
        expect(getIframeClasses(width, height)).toEqual([
          'gl-min-w-full gl-border-none',
          { 'gl-inset-0 gl-h-full gl-w-full': false },
        ]);
      });
    });
  });
});
