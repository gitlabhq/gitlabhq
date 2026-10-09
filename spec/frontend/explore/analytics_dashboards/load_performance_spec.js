import { markLoadStep, PanelsInViewTimer } from '~/explore/analytics_dashboards/load_performance';
import { performanceMarkAndMeasure } from '~/performance/utils';

jest.mock('~/performance/utils');

describe('explore dashboard load performance', () => {
  describe('markLoadStep', () => {
    beforeEach(() => {
      jest.spyOn(performance, 'clearMarks');
    });

    it('clears the previous mark before marking again', () => {
      markLoadStep({ mark: 'step-done' });

      expect(performance.clearMarks).toHaveBeenCalledWith('step-done');
      expect(performanceMarkAndMeasure).toHaveBeenCalledWith({
        mark: 'step-done',
        measures: [],
        sync: true,
      });
    });

    it('measures from the start mark', () => {
      markLoadStep({ mark: 'step-done', measure: 'Step', start: 'step-start' });

      expect(performanceMarkAndMeasure).toHaveBeenCalledWith({
        mark: 'step-done',
        measures: [{ name: 'Step', start: 'step-start' }],
        sync: true,
      });
    });
  });

  describe('PanelsInViewTimer', () => {
    let onDone;
    let scroller;

    const createPanel = ({ top, bottom }) => {
      const el = document.createElement('div');
      el.getBoundingClientRect = () => ({ top, bottom });
      scroller.appendChild(el);
      return el;
    };

    const createTimer = (expectedPanels) => new PanelsInViewTimer({ expectedPanels, onDone });

    beforeEach(() => {
      onDone = jest.fn();
      scroller = document.createElement('div');
      scroller.classList.add('js-static-panel-inner');
      scroller.getBoundingClientRect = () => ({ top: 0, bottom: 500 });
      document.body.appendChild(scroller);
    });

    afterEach(() => {
      scroller.remove();
    });

    it('finishes when every panel in view has settled, without waiting for the rest', () => {
      const inView = createPanel({ top: 0, bottom: 200 });
      const partlyInView = createPanel({ top: 400, bottom: 600 });
      const below = createPanel({ top: 800, bottom: 1000 });
      const timer = createTimer(3);

      [inView, partlyInView, below].forEach((el) => timer.register(el));
      timer.settle(inView);
      expect(onDone).not.toHaveBeenCalled();

      timer.settle(partlyInView);
      expect(onDone).toHaveBeenCalledTimes(1);

      timer.settle(below);
      expect(onDone).toHaveBeenCalledTimes(1);
    });

    it('waits for every expected panel to register before picking the panels in view', () => {
      const first = createPanel({ top: 0, bottom: 200 });
      const second = createPanel({ top: 200, bottom: 400 });
      const timer = createTimer(2);

      timer.register(first);
      timer.settle(first);
      expect(onDone).not.toHaveBeenCalled();

      timer.register(second);
      timer.settle(second);
      expect(onDone).toHaveBeenCalledTimes(1);
    });

    it('ignores panels that settle without registering', () => {
      const registered = createPanel({ top: 0, bottom: 200 });
      const timer = createTimer(1);

      timer.settle(createPanel({ top: 0, bottom: 200 }));
      timer.register(registered);

      expect(onDone).not.toHaveBeenCalled();
    });

    it('waits for a panel that re-queries after it settled', () => {
      const first = createPanel({ top: 0, bottom: 200 });
      const second = createPanel({ top: 200, bottom: 400 });
      const timer = createTimer(2);

      timer.register(first);
      timer.settle(first);
      timer.register(first);
      timer.register(second);
      timer.settle(second);
      expect(onDone).not.toHaveBeenCalled();

      timer.settle(first);
      expect(onDone).toHaveBeenCalledTimes(1);
    });

    it('waits for every panel when none is in view', () => {
      const first = createPanel({ top: 800, bottom: 1000 });
      const second = createPanel({ top: 1000, bottom: 1200 });
      const timer = createTimer(2);

      [first, second].forEach((el) => timer.register(el));
      timer.settle(first);
      expect(onDone).not.toHaveBeenCalled();

      timer.settle(second);
      expect(onDone).toHaveBeenCalledTimes(1);
    });

    it('does not finish once cancelled', () => {
      const panel = createPanel({ top: 0, bottom: 200 });
      const timer = createTimer(1);

      timer.register(panel);
      timer.cancel();
      timer.settle(panel);

      expect(onDone).not.toHaveBeenCalled();
    });
  });
});
