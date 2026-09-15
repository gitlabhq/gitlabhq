/* eslint-disable no-underscore-dangle */
import '~/entrypoints/coverage_persistence';

describe('coveragePathsPersistence', () => {
  const FOO = 'app/assets/javascripts/foo.js';
  const BAR = 'app/assets/javascripts/bar.js';

  const loaded = () => ({ s: { 0: 0, 1: 0 }, f: {}, b: {} });
  const executed = () => ({ s: { 0: 0, 1: 3 }, f: {}, b: {} });

  // Jest's coverage reporter reads window.__coverage__ too, so put the real one back.
  const realCoverage = window.__coverage__;

  beforeEach(() => {
    localStorage.clear();
    delete window.__coverageFilePaths;
  });

  afterEach(() => {
    window.__coverage__ = realCoverage;
  });

  describe('update', () => {
    it('records files with at least one hit counter', () => {
      window.__coverage__ = { [FOO]: executed(), [BAR]: loaded() };

      window.__coveragePathsPersistence.update();

      expect(window.__coveragePathsPersistence.getPaths()).toEqual([FOO]);
    });

    it.each([
      ['statements', { s: { 0: 1 } }],
      ['functions', { f: { 0: 2 } }],
      ['branches', { b: { 0: [0, 1] } }],
    ])('counts a file executed when %s were hit', (_, fileCoverage) => {
      window.__coverage__ = { [FOO]: fileCoverage };

      window.__coveragePathsPersistence.update();

      expect(window.__coveragePathsPersistence.getPaths()).toEqual([FOO]);
    });

    it('accumulates paths across page loads', () => {
      window.__coverage__ = { [FOO]: executed() };
      window.__coveragePathsPersistence.update();

      window.__coverage__ = { [BAR]: executed() };
      window.__coveragePathsPersistence.update();

      expect(window.__coveragePathsPersistence.getPaths()).toEqual([FOO, BAR]);
    });

    it('does not duplicate a path seen on more than one page', () => {
      window.__coverage__ = { [FOO]: executed() };

      window.__coveragePathsPersistence.update();
      window.__coveragePathsPersistence.update();

      expect(window.__coveragePathsPersistence.getPaths()).toEqual([FOO]);
    });
  });

  describe('reset', () => {
    it('drops paths accumulated by earlier page loads', () => {
      window.__coverage__ = { [FOO]: executed() };
      window.__coveragePathsPersistence.update();

      window.__coveragePathsPersistence.reset();

      expect(window.__coveragePathsPersistence.getPaths()).toEqual([]);
      expect(localStorage.getItem('__coverage_paths__')).toBe(null);
    });
  });
});
