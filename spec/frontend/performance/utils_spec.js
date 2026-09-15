import { performanceMarkAndMeasure } from '~/performance/utils';

describe('performanceMarkAndMeasure', () => {
  let rafCallback;
  let existingMarks;

  beforeEach(() => {
    rafCallback = null;
    existingMarks = ['existing-start-mark', 'existing-end-mark'];
    jest.spyOn(window, 'requestAnimationFrame').mockImplementation((cb) => {
      rafCallback = cb;
    });
    window.performance.mark = jest.fn();
    window.performance.measure = jest.fn();
    window.performance.getEntriesByName = jest
      .fn()
      .mockImplementation((name) => (existingMarks.includes(name) ? [{ name }] : []));
    window.performance.timing = { responseEnd: 123 };
  });

  afterEach(() => {
    delete window.performance.timing;
  });

  it('defers execution to the next animation frame by default', () => {
    performanceMarkAndMeasure({ mark: 'my-mark' });

    expect(window.performance.mark).not.toHaveBeenCalled();

    rafCallback();

    expect(window.performance.mark).toHaveBeenCalledWith('my-mark');
  });

  it('runs synchronously when sync is true', () => {
    performanceMarkAndMeasure({ sync: true, mark: 'my-mark' });

    expect(window.requestAnimationFrame).not.toHaveBeenCalled();
    expect(window.performance.mark).toHaveBeenCalledWith('my-mark');
  });

  it('does not set the mark again when it already exists', () => {
    performanceMarkAndMeasure({ sync: true, mark: 'existing-start-mark' });

    expect(window.performance.mark).not.toHaveBeenCalled();
  });

  it('runs measures whose marks exist', () => {
    performanceMarkAndMeasure({
      sync: true,
      measures: [{ name: 'my-measure', start: 'existing-start-mark', end: 'existing-end-mark' }],
    });

    expect(window.performance.measure).toHaveBeenCalledWith(
      'my-measure',
      'existing-start-mark',
      'existing-end-mark',
    );
  });

  it.each`
    scenario                       | start                    | end
    ${'the start mark is missing'} | ${'missing-mark'}        | ${'existing-end-mark'}
    ${'the end mark is missing'}   | ${'existing-start-mark'} | ${'missing-mark'}
  `('skips the measure when $scenario', ({ start, end }) => {
    performanceMarkAndMeasure({
      sync: true,
      measures: [{ name: 'my-measure', start, end }],
    });

    expect(window.performance.measure).not.toHaveBeenCalled();
  });

  it('runs measures referencing navigation timing attributes', () => {
    performanceMarkAndMeasure({
      sync: true,
      measures: [{ name: 'my-measure', start: 'responseEnd', end: 'existing-end-mark' }],
    });

    expect(window.performance.measure).toHaveBeenCalledWith(
      'my-measure',
      'responseEnd',
      'existing-end-mark',
    );
  });

  it('runs the measure when start and end are omitted', () => {
    performanceMarkAndMeasure({
      sync: true,
      measures: [{ name: 'my-measure', start: undefined, end: 'existing-end-mark' }],
    });

    expect(window.performance.measure).toHaveBeenCalledWith(
      'my-measure',
      undefined,
      'existing-end-mark',
    );
  });

  it('can set a mark and measure against it in the same call', () => {
    window.performance.mark = jest.fn((name) => existingMarks.push(name));

    performanceMarkAndMeasure({
      sync: true,
      mark: 'new-end-mark',
      measures: [{ name: 'my-measure', start: 'existing-start-mark', end: 'new-end-mark' }],
    });

    expect(window.performance.measure).toHaveBeenCalledWith(
      'my-measure',
      'existing-start-mark',
      'new-end-mark',
    );
  });

  it('does nothing when called with no arguments', () => {
    performanceMarkAndMeasure();

    rafCallback();

    expect(window.performance.mark).not.toHaveBeenCalled();
    expect(window.performance.measure).not.toHaveBeenCalled();
  });
});
