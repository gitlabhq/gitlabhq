import path from 'node:path';
import { createRequire } from 'node:module';
import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';

// The stubs must reach the copies the loader requires; Vitest's `import` loads separate ones.
/* eslint-disable import-x/no-commonjs */
const require = createRequire(import.meta.url);
const LOADER_PATH = require.resolve('../../../../../config/vue3migration/plugins/rspack_loader');
const aliases = require('../../../../../config/vue3migration/aliases');
const infection = require('../../../../../config/vue3migration/infection');
/* eslint-enable import-x/no-commonjs */

const CI_ROOT = '/builds/gitlab-org/gitlab';
const NIX_ROOT = '/nix/var/nix/builds/nix-12015-2632109856/source';
const IMPORTER = 'app/assets/javascripts/feature/deep/importer.js';

// Scanner edges from IMPORTER: specifier -> resolved file, relative to the checkout.
const EDGES = {
  '~/lib/shared': 'app/assets/javascripts/lib/shared.js',
  './sibling': 'app/assets/javascripts/feature/deep/sibling.js',
  '~/lib/query': 'app/assets/javascripts/lib/query.js?flavor=one',
  'ee/widget': 'ee/app/assets/javascripts/widget.js',
  '~/lib/plain': 'app/assets/javascripts/lib/plain.js',
};
const NOT_EXPOSED_TO_VUE = ['app/assets/javascripts/lib/plain.js'];

let originalContextAliases;

// The loader reads its aliases and the scanner data once per load, so each root needs a fresh copy.
const loadLoader = (root) => {
  const abs = (file) => `${root}/${file}`;
  const importers = [IMPORTER, 'app/assets/javascripts/top.js'];
  const graph = new Map(
    importers.map((importer) => [
      abs(importer),
      {
        exposedToVue: true,
        imports: Object.entries(EDGES).map(([source, file]) => ({ source, resolved: abs(file) })),
      },
    ]),
  );
  for (const file of Object.values(EDGES)) {
    const clean = infection.stripQuery(file);
    graph.set(abs(clean), { exposedToVue: !NOT_EXPOSED_TO_VUE.includes(clean), imports: [] });
  }

  aliases.CONTEXT_ALIASES = { vue: abs('app/assets/javascripts/lib/utils/vue3compat/vue.js') };
  vi.spyOn(infection, 'runInfectionScanner').mockImplementation(() => {});
  vi.spyOn(infection, 'loadScannerData').mockReturnValue(graph);
  delete require.cache[LOADER_PATH];
  const loader = require(LOADER_PATH);

  return (source, importer = IMPORTER) =>
    loader.call(
      {
        resourcePath: abs(importer),
        resourceQuery: '?vue3',
        emitWarning: (error) => {
          throw error;
        },
      },
      source,
    );
};

const rewrittenSpecifier = (output) => output.match(/'([^']+)'/)[1];

describe('config/vue3migration/plugins/rspack_loader', () => {
  beforeEach(() => {
    originalContextAliases = aliases.CONTEXT_ALIASES;
    vi.stubEnv('VUE_VERSION', '2');
  });

  afterEach(() => {
    aliases.CONTEXT_ALIASES = originalContextAliases;
    vi.unstubAllEnvs();
    vi.restoreAllMocks();
    delete require.cache[LOADER_PATH];
  });

  it('gives the same output wherever the checkout is', () => {
    const source = [
      "import shared from '~/lib/shared';",
      "import sibling from './sibling';",
      "import Vue from 'vue';",
      "export * from 'ee/widget';",
    ].join('\n');

    const fromCi = loadLoader(CI_ROOT)(source);
    const fromNix = loadLoader(NIX_ROOT)(source);

    expect(fromCi).toBe(fromNix);
    expect(fromCi).not.toContain(CI_ROOT);
  });

  describe('rewrites each import form', () => {
    it.each([
      ['a static import', "import shared from '~/lib/shared';"],
      ['a named re-export', "export { default } from '~/lib/shared';"],
      ['a star re-export', "export * from '~/lib/shared';"],
      ['a dynamic import', "const load = () => import('~/lib/shared');"],
      ['a require call', "const shared = require('~/lib/shared');"],
    ])('%s', (_, source) => {
      const output = loadLoader(CI_ROOT)(source);

      expect(output).toBe(source.replace('~/lib/shared', '../../lib/shared.js?vue3'));
    });
  });

  describe('keeps the resolved file and query', () => {
    it.each([
      ['a parent directory', '~/lib/shared', '../../lib/shared.js?vue3'],
      ['the same directory, with ./', './sibling', './sibling.js?vue3'],
      ['the resolved query', '~/lib/query', '../../lib/query.js?flavor=one&vue3'],
      ['the EE tree', 'ee/widget', '../../../../../ee/app/assets/javascripts/widget.js?vue3'],
      ['a context alias', 'vue', '../../lib/utils/vue3compat/vue.js?vue3'],
    ])('for %s', (_, specifier, expected) => {
      const output = loadLoader(CI_ROOT)(`import x from '${specifier}';`);

      expect(rewrittenSpecifier(output)).toBe(expected);
    });
  });

  it('points importers at different depths to one ?vue3 module', () => {
    const run = loadLoader(CI_ROOT);
    const resolveFrom = (importer) => {
      const specifier = rewrittenSpecifier(run("import x from '~/lib/shared';", importer));
      return path.posix.resolve(path.posix.dirname(`${CI_ROOT}/${importer}`), specifier);
    };

    expect(resolveFrom(IMPORTER)).toBe(`${CI_ROOT}/${EDGES['~/lib/shared']}?vue3`);
    expect(resolveFrom('app/assets/javascripts/top.js')).toBe(resolveFrom(IMPORTER));
  });

  it.each([
    ['a module not exposed to Vue', "import plain from '~/lib/plain';"],
    ['a special query', "import raw from './data.txt?raw';"],
    ['an import that already has ?vue3', "import x from './done.js?vue3';"],
  ])('leaves %s untouched', (_, source) => {
    expect(loadLoader(CI_ROOT)(source)).toBe(source);
  });
});
