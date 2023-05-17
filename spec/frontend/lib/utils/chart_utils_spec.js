import { firstAndLastY, getToolboxOptions } from '~/lib/utils/chart_utils';
import { __ } from '~/locale';
import * as iconUtils from '~/lib/utils/icon_utils';

jest.mock('~/lib/utils/icon_utils');

describe('Chart utils', () => {
  describe('firstAndLastY', () => {
    it('returns the first and last y-values of a given data set as an array', () => {
      const data = [
        ['', 1],
        ['', 2],
        ['', 3],
      ];

      expect(firstAndLastY(data)).toEqual([1, 3]);
    });
  });

  describe('getToolboxOptions', () => {
    describe('when icons are successfully fetched', () => {
      beforeEach(() => {
        iconUtils.getSvgIconPathContent.mockImplementation((name) =>
          Promise.resolve(`${name}-svg-path-mock`),
        );
      });

      it('returns toolbox config', async () => {
        await expect(getToolboxOptions()).resolves.toEqual({
          toolbox: {
            feature: {
              dataZoom: {
                icon: {
                  zoom: 'path://marquee-selection-svg-path-mock',
                  back: 'path://redo-svg-path-mock',
                },
              },
              restore: {
                icon: 'path://repeat-svg-path-mock',
              },
              saveAsImage: {
                icon: 'path://download-svg-path-mock',
              },
            },
          },
        });
      });
    });

    describe('when icons are not successfully fetched', () => {
      const error = new Error();

      beforeEach(() => {
        iconUtils.getSvgIconPathContent.mockRejectedValue(error);
        jest.spyOn(console, 'warn').mockImplementation();
      });

      it('returns empty object and calls `console.warn`', async () => {
        await expect(getToolboxOptions()).resolves.toEqual({});
        // eslint-disable-next-line no-console
        expect(console.warn).toHaveBeenCalledWith(
          __('SVG could not be rendered correctly: '),
          error,
        );
      });
    });
  });
});
