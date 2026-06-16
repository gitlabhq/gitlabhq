import { describe, it, expect } from 'vitest';
import vue3InfectionShared from '../../../../config/helpers/vue3_infection_shared';

// The module under test is CommonJS; rely on Node's CJS-default-import interop.
const {
  stripQuery,
  getQuery,
  hasVue3Query,
  hasSpecialQuery,
  appendVue3Query,
  createIsInfectable,
} = vue3InfectionShared;

describe('config/helpers/vue3_infection_shared', () => {
  describe('stripQuery', () => {
    it.each([
      ['returns an empty string for an empty input', '', ''],
      ['returns an empty string for undefined', undefined, ''],
      ['returns the id unchanged when no query is present', '/foo/bar.js', '/foo/bar.js'],
      ['strips a single query parameter', '/foo/bar.js?vue3', '/foo/bar.js'],
      ['strips multiple query parameters', '/foo/bar.js?vue3&worker', '/foo/bar.js'],
      ['returns an empty string when the id is just a query', '?vue3', ''],
    ])('%s', (_, input, expected) => {
      expect(stripQuery(input)).toBe(expected);
    });
  });

  describe('getQuery', () => {
    it.each([
      ['returns an empty string for an empty input', '', ''],
      ['returns an empty string for undefined', undefined, ''],
      ['returns an empty string when no query is present', '/foo/bar.js', ''],
      ['returns the query including the leading ?', '/foo/bar.js?vue3', '?vue3'],
      ['returns multiple query parameters', '/foo/bar.js?vue3&worker', '?vue3&worker'],
    ])('%s', (_, input, expected) => {
      expect(getQuery(input)).toBe(expected);
    });
  });

  describe('hasVue3Query', () => {
    it.each([
      ['returns false for an empty input', '', false],
      ['returns false for undefined', undefined, false],
      ['returns false when no query is present', '/foo/bar.js', false],
      ['returns false when a different query is present', '/foo/bar.js?worker', false],
      ['returns true when ?vue3 is the only param', '/foo/bar.js?vue3', true],
      ['returns true when ?vue3 is one of several params', '/foo/bar.js?worker&vue3', true],
    ])('%s', (_, input, expected) => {
      expect(hasVue3Query(input)).toBe(expected);
    });
  });

  describe('hasSpecialQuery', () => {
    it('returns false when no query is present', () => {
      expect(hasSpecialQuery('/foo/bar.js')).toBe(false);
    });

    it('returns false for the vue3 query', () => {
      expect(hasSpecialQuery('/foo/bar.js?vue3')).toBe(false);
    });

    it.each(['vue', 'worker', 'raw', 'url', 'inline', 'sharedworker'])(
      'returns true for the special query %s',
      (param) => {
        expect(hasSpecialQuery(`/foo/bar.js?${param}`)).toBe(true);
      },
    );

    it('returns true when a special query is mixed with other params', () => {
      expect(hasSpecialQuery('/foo/bar.js?vue3&worker')).toBe(true);
    });

    it('returns false for an unrelated query parameter', () => {
      expect(hasSpecialQuery('/foo/bar.js?something=else')).toBe(false);
    });

    it('matches special queries by exact param name, not substring', () => {
      // `workerish` should not match `worker`.
      expect(hasSpecialQuery('/foo/bar.js?workerish')).toBe(false);
    });
  });

  describe('appendVue3Query', () => {
    it('appends ?vue3 when no query exists', () => {
      expect(appendVue3Query('/foo/bar.js')).toBe('/foo/bar.js?vue3');
    });

    it('appends &vue3 when another query already exists', () => {
      expect(appendVue3Query('/foo/bar.js?worker')).toBe('/foo/bar.js?worker&vue3');
    });

    it('is a no-op when the id already contains ?vue3', () => {
      expect(appendVue3Query('/foo/bar.js?vue3')).toBe('/foo/bar.js?vue3');
    });

    it('is a no-op when vue3 is one of several existing params', () => {
      expect(appendVue3Query('/foo/bar.js?worker&vue3')).toBe('/foo/bar.js?worker&vue3');
    });
  });

  describe('createIsInfectable', () => {
    // Pick a path that matches INFECTABLE_RE (`.js`/`.mjs`/`.vue`) and is not
    // on the INFECTION_BLOCKLIST, so the predicate's "interesting" branches run.
    const INFECTABLE_PATH = '/repo/app/assets/javascripts/some_module.js';
    const BLOCKED_PATH = 'app/assets/javascripts/super_sidebar/state.js';
    const NON_INFECTABLE_PATH = '/repo/app/assets/javascripts/styles.css';

    it('returns false for files that do not match the infectable extensions', () => {
      const isInfectable = createIsInfectable(null);

      expect(isInfectable(NON_INFECTABLE_PATH)).toBe(false);
    });

    it('returns false for files on the infection blocklist', () => {
      const isInfectable = createIsInfectable(null);

      expect(isInfectable(BLOCKED_PATH)).toBe(false);
    });

    it('returns true for infectable files when no scanner graph is provided', () => {
      const isInfectable = createIsInfectable(null);

      expect(isInfectable(INFECTABLE_PATH)).toBe(true);
    });

    it('ignores query strings when checking the path', () => {
      const isInfectable = createIsInfectable(null);

      expect(isInfectable(`${INFECTABLE_PATH}?vue3`)).toBe(true);
      expect(isInfectable(`${NON_INFECTABLE_PATH}?vue3`)).toBe(false);
    });

    it('returns the scanner graph entry value when the file is present', () => {
      const graph = new Map([[INFECTABLE_PATH, { infected: true, appRoot: false }]]);
      const isInfectable = createIsInfectable(graph);

      expect(isInfectable(INFECTABLE_PATH)).toBe(true);
    });

    it('returns false when the scanner graph marks the file as not infected', () => {
      const graph = new Map([[INFECTABLE_PATH, { infected: false, appRoot: false }]]);
      const isInfectable = createIsInfectable(graph);

      expect(isInfectable(INFECTABLE_PATH)).toBe(false);
    });

    it('throws when a file is not found in the scanner graph', () => {
      const graph = new Map();
      const isInfectable = createIsInfectable(graph);

      expect(() => isInfectable(INFECTABLE_PATH)).toThrow(
        /File not found in scanner data/,
      );
    });

    it('uses shouldExclude to short-circuit to false before consulting the graph', () => {
      const graph = new Map([[INFECTABLE_PATH, { infected: true, appRoot: false }]]);
      const isInfectable = createIsInfectable(graph, {
        shouldExclude: (clean) => clean === INFECTABLE_PATH,
      });

      expect(isInfectable(INFECTABLE_PATH)).toBe(false);
    });

    it('uses shouldBypass to short-circuit to true without a graph lookup', () => {
      const graph = new Map(); // intentionally empty: a graph lookup would throw
      const isInfectable = createIsInfectable(graph, {
        shouldBypass: (clean) => clean === INFECTABLE_PATH,
      });

      expect(isInfectable(INFECTABLE_PATH)).toBe(true);
    });

    it('prefers shouldExclude over shouldBypass when both match', () => {
      const graph = new Map([[INFECTABLE_PATH, { infected: true, appRoot: false }]]);
      const isInfectable = createIsInfectable(graph, {
        shouldExclude: () => true,
        shouldBypass: () => true,
      });

      expect(isInfectable(INFECTABLE_PATH)).toBe(false);
    });
  });
});
