import { setHTMLFixture } from 'helpers/fixtures';
import { scrollPastCoveringElements } from '~/lib/utils/sticky';

describe('Sticky elements utils', () => {
  describe('scrollPastCoveringElements', () => {
    const getPanel = () => document.querySelector('.js-static-panel-inner');
    const getElement = () => document.querySelector('#element');
    const getStickyEl = () => document.querySelector('#sticky-header');
    let elementFromPointSpy;

    beforeEach(() => {
      setHTMLFixture(`
        <div class="js-static-panel-inner">
          <div id="sticky-header"></div>
          <div id="element"></div>
        </div>
      `);
      // jsdom doesn't implement elementFromPoint, so we define it
      elementFromPointSpy = jest.fn();
      document.elementFromPoint = elementFromPointSpy;
      jest.spyOn(getPanel(), 'scrollBy').mockImplementation(() => {});
      // Make the sticky header return position: sticky from getComputedStyle
      jest.spyOn(window, 'getComputedStyle').mockReturnValue({ position: 'sticky' });
    });

    function mockCovered({ elementTop, coveringBottom, iterations = 1 }) {
      jest
        .spyOn(getElement(), 'getBoundingClientRect')
        .mockReturnValue({ top: elementTop, left: 10 });
      jest
        .spyOn(getStickyEl(), 'getBoundingClientRect')
        .mockReturnValue({ bottom: coveringBottom });

      for (let i = 0; i < iterations; i += 1) {
        elementFromPointSpy.mockReturnValueOnce(getStickyEl());
      }
      elementFromPointSpy.mockReturnValue(getElement());
    }

    it('scrolls by the amount needed to reveal the element', () => {
      mockCovered({ elementTop: 80, coveringBottom: 100 });

      scrollPastCoveringElements(getElement());

      expect(getPanel().scrollBy).toHaveBeenCalledWith({
        top: -20,
        behavior: 'instant',
      });
      expect(getPanel().scrollBy).toHaveBeenCalledTimes(1);
    });

    it('stops when scrollAmount is zero or negative', () => {
      mockCovered({ elementTop: 60, coveringBottom: 50 });

      scrollPastCoveringElements(getElement());

      expect(getPanel().scrollBy).not.toHaveBeenCalled();
    });

    it('stops after maxIterations to prevent infinite loops', () => {
      mockCovered({ elementTop: 90, coveringBottom: 100, iterations: 10 });

      scrollPastCoveringElements(getElement(), 5);

      expect(getPanel().scrollBy).toHaveBeenCalledTimes(5);
    });

    it('uses default maxIterations of 10', () => {
      mockCovered({ elementTop: 90, coveringBottom: 100, iterations: 20 });

      scrollPastCoveringElements(getElement());

      expect(getPanel().scrollBy).toHaveBeenCalledTimes(10);
    });

    it('does nothing when no covering element exists', () => {
      jest.spyOn(getElement(), 'getBoundingClientRect').mockReturnValue({ top: 80, left: 10 });
      elementFromPointSpy.mockReturnValue(getElement());

      scrollPastCoveringElements(getElement());

      expect(getPanel().scrollBy).not.toHaveBeenCalled();
    });

    it('does nothing when elementFromPoint returns null', () => {
      jest.spyOn(getElement(), 'getBoundingClientRect').mockReturnValue({ top: 80, left: 10 });
      elementFromPointSpy.mockReturnValue(null);

      scrollPastCoveringElements(getElement());

      expect(getPanel().scrollBy).not.toHaveBeenCalled();
    });

    it('hides tooltips during measurement', () => {
      const tooltip = document.createElement('div');
      tooltip.setAttribute('role', 'tooltip');
      document.body.appendChild(tooltip);

      jest.spyOn(getElement(), 'getBoundingClientRect').mockReturnValue({ top: 80, left: 10 });
      elementFromPointSpy.mockImplementation(() => {
        // Tooltip should be hidden during elementFromPoint calls
        expect(tooltip.style.display).toBe('none');
        return getElement();
      });

      scrollPastCoveringElements(getElement());

      expect(tooltip.style.display).toBe('');
    });
  });
});
