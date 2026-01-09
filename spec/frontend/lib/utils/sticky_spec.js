import { setHTMLFixture } from 'helpers/fixtures';
import { getCoveringElement, observeIntersectionOnce } from '~/lib/utils/viewport';
import { scrollPastCoveringElements } from '~/lib/utils/sticky';

jest.mock('~/lib/utils/viewport');

describe('Sticky elements utils', () => {
  describe('scrollPastCoveringElements', () => {
    const getPanel = () => document.querySelector('.js-static-panel-inner');
    const getElement = () => document.querySelector('#element');

    beforeEach(() => {
      setHTMLFixture(`
        <div class="js-static-panel-inner">
          <div id="element"></div>
        </div>
      `);
      jest.spyOn(getPanel(), 'scrollBy');
    });

    it('scrolls by the amount needed to reveal the element', async () => {
      const coveringElement = document.createElement('div');
      getCoveringElement.mockResolvedValueOnce(coveringElement).mockResolvedValueOnce(null);
      observeIntersectionOnce
        .mockResolvedValueOnce({ intersectionRect: { bottom: 100 } })
        .mockResolvedValueOnce({ intersectionRect: { top: 80 } });

      await scrollPastCoveringElements(getElement());

      expect(getPanel().scrollBy).toHaveBeenCalledWith({
        top: -20,
        behavior: 'instant',
      });
    });

    it('iterates until no covering element remains', async () => {
      const coveringElement = document.createElement('div');
      getCoveringElement
        .mockResolvedValueOnce(coveringElement)
        .mockResolvedValueOnce(coveringElement)
        .mockResolvedValueOnce(null);
      observeIntersectionOnce
        .mockResolvedValueOnce({ intersectionRect: { bottom: 100 } })
        .mockResolvedValueOnce({ intersectionRect: { top: 90 } })
        .mockResolvedValueOnce({ intersectionRect: { bottom: 50 } })
        .mockResolvedValueOnce({ intersectionRect: { top: 40 } });

      await scrollPastCoveringElements(getElement());

      expect(getPanel().scrollBy).toHaveBeenCalledTimes(2);
      expect(getPanel().scrollBy).toHaveBeenNthCalledWith(1, {
        top: -10,
        behavior: 'instant',
      });
      expect(getPanel().scrollBy).toHaveBeenNthCalledWith(2, {
        top: -10,
        behavior: 'instant',
      });
    });

    it('stops when scrollAmount is zero or negative', async () => {
      getCoveringElement.mockResolvedValue(document.createElement('div'));
      observeIntersectionOnce
        .mockResolvedValueOnce({ intersectionRect: { bottom: 50 } })
        .mockResolvedValueOnce({ intersectionRect: { top: 60 } });

      await scrollPastCoveringElements(getElement());

      expect(getPanel().scrollBy).not.toHaveBeenCalled();
    });

    it('stops after maxIterations to prevent infinite loops', async () => {
      const coveringElement = document.createElement('div');
      getCoveringElement.mockResolvedValue(coveringElement);
      observeIntersectionOnce.mockResolvedValue({ intersectionRect: { bottom: 100, top: 90 } });

      await scrollPastCoveringElements(getElement(), 5);

      expect(getPanel().scrollBy).toHaveBeenCalledTimes(5);
    });

    it('uses default maxIterations of 10', async () => {
      const coveringElement = document.createElement('div');
      getCoveringElement.mockResolvedValue(coveringElement);
      observeIntersectionOnce.mockResolvedValue({ intersectionRect: { bottom: 100, top: 90 } });

      await scrollPastCoveringElements(getElement());

      expect(getPanel().scrollBy).toHaveBeenCalledTimes(10);
    });

    it('does nothing when no covering element exists', async () => {
      getCoveringElement.mockResolvedValue(null);

      await scrollPastCoveringElements(getElement());

      expect(getPanel().scrollBy).not.toHaveBeenCalled();
    });
  });
});
