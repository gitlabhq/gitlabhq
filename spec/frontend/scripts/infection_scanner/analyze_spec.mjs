import path from 'node:path';
import { describe, it, expect, beforeAll } from 'vitest';
import {
  analyze,
  detectAppRoot,
  extractScriptContent,
  computeInfected,
  createResolver,
} from '../../../../scripts/frontend/infection_scanner/analyze';

const FIXTURES_DIR = path.resolve(import.meta.dirname, 'fixtures');
const fixture = (...parts) => path.join(FIXTURES_DIR, ...parts);

describe('infection scanner', () => {
  describe('detectAppRoot', () => {
    it('detects simple new Vue()', () => {
      expect(detectAppRoot("import Vue from 'vue'; new Vue({ el: '#app' });")).toBe(true);
    });

    it('detects new Vue() with Vue.use()', () => {
      expect(detectAppRoot("import Vue from 'vue'; Vue.use(Vuex); new Vue({});")).toBe(true);
    });

    it('detects with multiple Vue.use() calls', () => {
      expect(
        detectAppRoot("import Vue from 'vue'; Vue.use(Vuex); Vue.use(Router); new Vue({});"),
      ).toBe(true);
    });

    it('detects with custom import name', () => {
      expect(detectAppRoot("import MyVue from 'vue'; new MyVue({ el: '#app' });")).toBe(true);
    });

    it('rejects named imports from vue', () => {
      expect(detectAppRoot("import { computed } from 'vue';")).toBe(false);
    });

    it('rejects mixed default + named imports', () => {
      expect(detectAppRoot("import Vue, { computed } from 'vue'; new Vue({});")).toBe(false);
    });

    it('rejects Vue.component()', () => {
      expect(detectAppRoot("import Vue from 'vue'; Vue.component('x', {}); new Vue({});")).toBe(
        false,
      );
    });

    it('rejects Vue.extend()', () => {
      expect(detectAppRoot("import Vue from 'vue'; Vue.extend({});")).toBe(false);
    });

    it('rejects Vue.use() + Vue.extend()', () => {
      expect(
        detectAppRoot("import Vue from 'vue'; Vue.use(Vuex); Vue.extend({}); new Vue({});"),
      ).toBe(false);
    });

    it('rejects when there is no new Vue()', () => {
      expect(detectAppRoot("import Vue from 'vue'; Vue.use(Vuex);")).toBe(false);
    });

    it('rejects when there is no vue import', () => {
      expect(detectAppRoot("import Foo from 'bar'; new Foo({});")).toBe(false);
    });

    it('ignores Vue references in single-line comments', () => {
      const code = ["import Vue from 'vue';", '// Vue.component("x", {});', 'new Vue({});'].join(
        '\n',
      );
      expect(detectAppRoot(code)).toBe(true);
    });

    it('ignores Vue references in block comments', () => {
      const code = ["import Vue from 'vue';", '/* Vue.extend({}) */', 'new Vue({});'].join('\n');
      expect(detectAppRoot(code)).toBe(true);
    });
  });

  describe('extractScriptContent', () => {
    it('extracts script content from a Vue SFC', () => {
      const sfc = '<script>\nconst x = 1;\n</script>\n<template><div/></template>';
      expect(extractScriptContent(sfc)).toBe('\nconst x = 1;\n');
    });

    it('extracts script with attributes', () => {
      const sfc = '<script lang="ts" setup>\nconst x = 1;\n</script>';
      expect(extractScriptContent(sfc)).toBe('\nconst x = 1;\n');
    });

    it('returns empty string when no script block exists', () => {
      expect(extractScriptContent('<template><div/></template>')).toBe('');
    });

    it('returns empty string for empty input', () => {
      expect(extractScriptContent('')).toBe('');
    });
  });

  describe('createResolver', () => {
    const rootPath = fixture('basic');
    const resolver = createResolver({ aliasMap: {}, rootPath });

    it('resolves relative .js imports', () => {
      const from = fixture('basic', 'entry.js');
      expect(resolver.resolveModule('./app.js', from)).toBe(fixture('basic', 'app.js'));
    });

    it('resolves relative imports without extension', () => {
      const from = fixture('basic', 'entry.js');
      expect(resolver.resolveModule('./app', from)).toBe(fixture('basic', 'app.js'));
    });

    it('resolves .vue files', () => {
      const from = fixture('basic', 'with_component.js');
      expect(resolver.resolveModule('./component.vue', from)).toBe(
        fixture('basic', 'component.vue'),
      );
    });

    it('resolves node_modules via package.json main', () => {
      const from = fixture('basic', 'entry.js');
      expect(resolver.resolveModule('vue', from)).toBe(
        fixture('basic', 'node_modules', 'vue', 'index.js'),
      );
    });

    it('applies prefix aliases', () => {
      const aliasedResolver = createResolver({
        aliasMap: { '~': fixture('basic') },
        rootPath: fixture('basic'),
      });
      const from = fixture('basic', 'entry.js');
      expect(aliasedResolver.resolveModule('~/utils', from)).toBe(fixture('basic', 'utils.js'));
    });

    it('applies exact aliases', () => {
      const aliasedResolver = createResolver({
        aliasMap: { 'my-utils$': fixture('basic', 'utils.js') },
        rootPath: fixture('basic'),
      });
      const from = fixture('basic', 'entry.js');
      expect(aliasedResolver.resolveModule('my-utils', from)).toBe(fixture('basic', 'utils.js'));
    });

    it('strips ?vue3 suffix before resolving', () => {
      const from = fixture('basic', 'entry.js');
      expect(resolver.resolveModule('./app?vue3', from)).toBe(fixture('basic', 'app.js'));
    });

    it('prefers pkg.exports over pkg.module', () => {
      const pkgResolver = createResolver({
        aliasMap: {},
        rootPath: fixture('pkg_exports'),
      });
      const from = fixture('pkg_exports', 'entry.js');
      const resolved = pkgResolver.resolveModule('some-pkg', from);
      expect(resolved).toBe(
        fixture('pkg_exports', 'node_modules', 'some-pkg', 'dist', 'index.mjs'),
      );
    });

    it('resolves directory imports via index.js', () => {
      const indexResolver = createResolver({
        aliasMap: {},
        rootPath: fixture('index_resolution'),
      });
      const from = fixture('index_resolution', 'entry.js');
      expect(indexResolver.resolveModule('./subdir', from)).toBe(
        fixture('index_resolution', 'subdir', 'index.js'),
      );
    });

    it('falls back to pkg.module when no pkg.exports', () => {
      const moduleResolver = createResolver({
        aliasMap: {},
        rootPath: fixture('pkg_module_fallback'),
      });
      const from = fixture('pkg_module_fallback', 'entry.js');
      expect(moduleResolver.resolveModule('fallback-pkg', from)).toBe(
        fixture('pkg_module_fallback', 'node_modules', 'fallback-pkg', 'dist', 'index.esm.js'),
      );
    });

    it('returns null for unresolvable specifiers', () => {
      const from = fixture('basic', 'entry.js');
      expect(resolver.resolveModule('nonexistent-package', from)).toBeNull();
    });

    it('returns null for unresolvable relative paths', () => {
      const from = fixture('basic', 'entry.js');
      expect(resolver.resolveModule('./does_not_exist', from)).toBeNull();
    });

    it('resolves nested node_modules from the importing file directory', () => {
      const nestedResolver = createResolver({
        aliasMap: {},
        rootPath: fixture('nested_node_modules'),
      });
      const from = fixture(
        'nested_node_modules',
        'node_modules',
        'outer-pkg',
        'index.js',
      );
      expect(nestedResolver.resolveModule('inner-pkg', from)).toBe(
        fixture(
          'nested_node_modules',
          'node_modules',
          'outer-pkg',
          'node_modules',
          'inner-pkg',
          'index.js',
        ),
      );
    });

    it('resolves browser field (string form) as an alternative', () => {
      const browserResolver = createResolver({
        aliasMap: {},
        rootPath: fixture('browser_field'),
      });
      const from = fixture('browser_field', 'entry.js');
      const all = browserResolver.resolveModuleAll('browser-pkg', from);
      expect(all).toContain(
        fixture('browser_field', 'node_modules', 'browser-pkg', 'dist', 'index.js'),
      );
      expect(all).toContain(
        fixture('browser_field', 'node_modules', 'browser-pkg', 'dist', 'browser.js'),
      );
    });

    it('resolves browser field (object form) as an alternative', () => {
      const remapResolver = createResolver({
        aliasMap: {},
        rootPath: fixture('browser_object_remap'),
      });
      const from = fixture('browser_object_remap', 'entry.js');
      const all = remapResolver.resolveModuleAll('remap-pkg', from);
      expect(all).toContain(
        fixture('browser_object_remap', 'node_modules', 'remap-pkg', 'dist', 'index.js'),
      );
      expect(all).toContain(
        fixture('browser_object_remap', 'node_modules', 'remap-pkg', 'dist', 'browser.js'),
      );
    });

    it('resolveModuleAll returns all alternatives for pkg with exports + module', () => {
      const pkgResolver = createResolver({
        aliasMap: {},
        rootPath: fixture('pkg_exports'),
      });
      const from = fixture('pkg_exports', 'entry.js');
      const all = pkgResolver.resolveModuleAll('some-pkg', from);
      expect(all).toContain(
        fixture('pkg_exports', 'node_modules', 'some-pkg', 'dist', 'index.mjs'),
      );
      expect(all).toContain(
        fixture('pkg_exports', 'node_modules', 'some-pkg', 'dist', 'index.esm.js'),
      );
    });

    it('resolveModuleAll returns single-element array for relative imports', () => {
      const from = fixture('basic', 'entry.js');
      const all = resolver.resolveModuleAll('./app', from);
      expect(all).toEqual([fixture('basic', 'app.js')]);
    });

    it('resolveModuleAll returns null for unresolvable specifiers', () => {
      const from = fixture('basic', 'entry.js');
      expect(resolver.resolveModuleAll('nonexistent-package', from)).toBeNull();
    });

    it('uses fallbackResolve when standard resolution fails', () => {
      const fallbackPath = fixture('basic', 'utils.js');
      const fallbackResolver = createResolver({
        aliasMap: {},
        rootPath: fixture('basic'),
        fallbackResolve: () => fallbackPath,
      });
      const from = fixture('basic', 'entry.js');
      expect(fallbackResolver.resolveModule('nonexistent-package', from)).toBe(fallbackPath);
    });

    it('does not call fallbackResolve when standard resolution succeeds', () => {
      let called = false;
      const fallbackResolver = createResolver({
        aliasMap: {},
        rootPath: fixture('basic'),
        fallbackResolve: () => {
          called = true;
          return null;
        },
      });
      const from = fixture('basic', 'entry.js');
      fallbackResolver.resolveModule('vue', from);
      expect(called).toBe(false);
    });
  });

  describe('analyze', () => {
    describe('basic infection propagation', () => {
      let result;

      beforeAll(async () => {
        result = await analyze({
          rootPath: fixture('basic'),
          entrypoints: { main: fixture('basic', 'entry.js') },
          infectionSpecifiers: ['infection-pkg'],
        });
      });

      it('includes reachable files in the graph', () => {
        expect(result.graph[fixture('basic', 'entry.js')]).toBeDefined();
        expect(result.graph[fixture('basic', 'app.js')]).toBeDefined();
        expect(result.graph[fixture('basic', 'utils.js')]).toBeDefined();
      });

      it('does not include unreachable files', () => {
        expect(result.graph[fixture('basic', 'clean.js')]).toBeUndefined();
      });

      it('marks direct infection source as infected', () => {
        expect(result.graph[fixture('basic', 'app.js')].infected).toBe(true);
      });

      it('propagates infection to importers of infected files', () => {
        expect(result.graph[fixture('basic', 'entry.js')].infected).toBe(true);
      });

      it('does not infect files that do not import infected code', () => {
        expect(result.graph[fixture('basic', 'utils.js')].infected).toBe(false);
      });

      it('detects app roots', () => {
        expect(result.graph[fixture('basic', 'entry.js')].appRoot).toBe(true);
      });

      it('marks non-app-root files correctly', () => {
        expect(result.graph[fixture('basic', 'app.js')].appRoot).toBe(false);
        expect(result.graph[fixture('basic', 'utils.js')].appRoot).toBe(false);
      });

      it('tracks infection reasons', () => {
        const app = result.graph[fixture('basic', 'app.js')];
        expect(app.infectionReasons).toEqual(
          expect.arrayContaining([expect.objectContaining({ reason: 'infection-pkg' })]),
        );
      });
    });

    describe('Vue SFC support', () => {
      let result;

      beforeAll(async () => {
        result = await analyze({
          rootPath: fixture('basic'),
          entrypoints: { main: fixture('basic', 'with_component.js') },
          infectionSpecifiers: ['infection-pkg'],
        });
      });

      it('parses .vue files and follows their imports', () => {
        expect(result.graph[fixture('basic', 'component.vue')]).toBeDefined();
        expect(result.graph[fixture('basic', 'utils.js')]).toBeDefined();
      });
    });

    describe('app root as infection barrier', () => {
      let result;

      beforeAll(async () => {
        result = await analyze({
          rootPath: fixture('app_root_barrier'),
          entrypoints: {
            page: fixture('app_root_barrier', 'page.js'),
            app_a: fixture('app_root_barrier', 'app_a.js'),
          },
          infectionSpecifiers: ['infection-pkg'],
        });
      });

      it('infects the direct infection source', () => {
        expect(result.graph[fixture('app_root_barrier', 'infected_lib.js')].infected).toBe(true);
      });

      it('infects the app root that imports infected code', () => {
        expect(result.graph[fixture('app_root_barrier', 'app_b.js')].infected).toBe(true);
      });

      it('marks app_b as an app root', () => {
        expect(result.graph[fixture('app_root_barrier', 'app_b.js')].appRoot).toBe(true);
      });

      it('does NOT propagate infection past the app root', () => {
        expect(result.graph[fixture('app_root_barrier', 'page.js')].infected).toBe(false);
      });

      it('does NOT infect unrelated app roots sharing a clean dependency', () => {
        expect(result.graph[fixture('app_root_barrier', 'app_a.js')].infected).toBe(false);
      });

      it('does NOT infect shared clean libraries', () => {
        expect(result.graph[fixture('app_root_barrier', 'shared.js')].infected).toBe(false);
      });
    });
  });

  describe('computeInfected', () => {
    it('does not infect files with no infection sources', () => {
      const graph = {
        'a.js': [{ source: './b.js', resolved: 'b.js' }],
        'b.js': [],
      };
      const { infectedSet } = computeInfected(graph, new Set(), ['bad-pkg']);
      expect(infectedSet.size).toBe(0);
    });

    it('infects direct importers of infection sources', () => {
      const graph = {
        'a.js': [{ source: 'bad-pkg', resolved: null }],
        'b.js': [{ source: './a.js', resolved: 'a.js' }],
        'c.js': [],
      };
      const { infectedSet } = computeInfected(graph, new Set(), ['bad-pkg']);
      expect(infectedSet.has('a.js')).toBe(true);
      expect(infectedSet.has('b.js')).toBe(true);
      expect(infectedSet.has('c.js')).toBe(false);
    });

    it('stops propagation at app roots', () => {
      const graph = {
        'lib.js': [{ source: 'bad-pkg', resolved: null }],
        'app.js': [{ source: './lib.js', resolved: 'lib.js' }],
        'page.js': [{ source: './app.js', resolved: 'app.js' }],
      };
      const appRoots = new Set(['app.js']);
      const { infectedSet } = computeInfected(graph, appRoots, ['bad-pkg']);
      expect(infectedSet.has('lib.js')).toBe(true);
      expect(infectedSet.has('app.js')).toBe(true);
      expect(infectedSet.has('page.js')).toBe(false);
    });

    it('handles multiple infection chains', () => {
      const graph = {
        'a.js': [{ source: 'bad-pkg', resolved: null }],
        'b.js': [{ source: 'other-bad', resolved: null }],
        'c.js': [
          { source: './a.js', resolved: 'a.js' },
          { source: './b.js', resolved: 'b.js' },
        ],
      };
      const { infectedSet } = computeInfected(graph, new Set(), ['bad-pkg', 'other-bad']);
      expect(infectedSet.has('a.js')).toBe(true);
      expect(infectedSet.has('b.js')).toBe(true);
      expect(infectedSet.has('c.js')).toBe(true);
    });

    it('handles subpath infection specifiers', () => {
      const graph = {
        'a.js': [{ source: 'bad-pkg/utils', resolved: null }],
      };
      const { infectedSet } = computeInfected(graph, new Set(), ['bad-pkg']);
      expect(infectedSet.has('a.js')).toBe(true);
    });

    it('propagates infection transitively (A→B→C)', () => {
      const graph = {
        'a.js': [{ source: 'bad-pkg', resolved: null }],
        'b.js': [{ source: './a.js', resolved: 'a.js' }],
        'c.js': [{ source: './b.js', resolved: 'b.js' }],
      };
      const { infectedSet } = computeInfected(graph, new Set(), ['bad-pkg']);
      expect(infectedSet.has('a.js')).toBe(true);
      expect(infectedSet.has('b.js')).toBe(true);
      expect(infectedSet.has('c.js')).toBe(true);
    });

    it('returns infectionTriggers mapping files to their infection sources', () => {
      const graph = {
        'a.js': [{ source: 'bad-pkg', resolved: null }],
        'b.js': [{ source: './a.js', resolved: 'a.js' }],
      };
      const { infectionTriggers } = computeInfected(graph, new Set(), ['bad-pkg']);
      expect(infectionTriggers.get('a.js')).toEqual(['a.js']);
      expect(infectionTriggers.get('b.js')).toEqual(['a.js']);
    });

    it('does not include clean files in infectionTriggers', () => {
      const graph = {
        'a.js': [{ source: 'bad-pkg', resolved: null }],
        'b.js': [],
      };
      const { infectionTriggers } = computeInfected(graph, new Set(), ['bad-pkg']);
      expect(infectionTriggers.has('b.js')).toBe(false);
    });
  });

  describe('analyze — additional scenarios', () => {
    it('passes aliasMap through to resolver', async () => {
      const result = await analyze({
        rootPath: fixture('basic'),
        entrypoints: { main: fixture('basic', 'entry.js') },
        infectionSpecifiers: ['infection-pkg'],
        aliasMap: { '~': fixture('basic') },
      });
      expect(result.graph[fixture('basic', 'entry.js')]).toBeDefined();
    });

    it('includes infectionReasonCount for infected files', async () => {
      const result = await analyze({
        rootPath: fixture('basic'),
        entrypoints: { main: fixture('basic', 'entry.js') },
        infectionSpecifiers: ['infection-pkg'],
      });
      const app = result.graph[fixture('basic', 'app.js')];
      expect(app.infectionReasonCount).toBeGreaterThanOrEqual(1);
    });

    it('does not include infectionReasons for clean files', async () => {
      const result = await analyze({
        rootPath: fixture('basic'),
        entrypoints: { main: fixture('basic', 'entry.js') },
        infectionSpecifiers: ['infection-pkg'],
      });
      const utils = result.graph[fixture('basic', 'utils.js')];
      expect(utils.infectionReasons).toBeUndefined();
      expect(utils.infectionReasonCount).toBeUndefined();
    });

    it('returns entrypoints in result', async () => {
      const entrypoints = { main: fixture('basic', 'entry.js') };
      const result = await analyze({
        rootPath: fixture('basic'),
        entrypoints,
        infectionSpecifiers: ['infection-pkg'],
      });
      expect(result.entrypoints).toEqual(entrypoints);
    });

    it('includes all resolution alternatives in the graph', async () => {
      const result = await analyze({
        rootPath: fixture('pkg_exports'),
        entrypoints: { main: fixture('pkg_exports', 'entry.js') },
        infectionSpecifiers: [],
      });
      // Both the exports path and the module path should appear in the graph
      const exportPath = fixture('pkg_exports', 'node_modules', 'some-pkg', 'dist', 'index.mjs');
      const modulePath = fixture('pkg_exports', 'node_modules', 'some-pkg', 'dist', 'index.esm.js');
      expect(result.graph[exportPath]).toBeDefined();
      expect(result.graph[modulePath]).toBeDefined();
    });

    it('calls onProgress during analysis', async () => {
      const calls = [];
      await analyze({
        rootPath: fixture('basic'),
        entrypoints: { main: fixture('basic', 'entry.js') },
        infectionSpecifiers: ['infection-pkg'],
        onProgress(parsed, total) {
          calls.push({ parsed, total });
        },
      });
      // Should have at least the final progress call
      expect(calls.length).toBeGreaterThanOrEqual(1);
      const last = calls[calls.length - 1];
      expect(last.parsed).toBe(last.total);
    });
  });
});
