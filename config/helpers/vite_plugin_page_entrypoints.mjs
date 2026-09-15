import path from 'node:path';
import { createRequire } from 'node:module';
import { generateEntries, applyVue3Migrations } from '../webpack.helpers';

const require = createRequire(import.meta.url);
const { appendVue3Query, loadVue3Migrations } = require('./vue3_migration_loader');
const { baseEntryPoints } = require('./entry_points');

const entrypointsDir = '/javascripts/entrypoints/';
const actualDirRoot = path.resolve(__dirname, '../../app/assets/javascripts/');

/**
 * This Plugin provides virtual entrypoints for our automatic
 * rails-route to entrypoint mapping during development
 *
 * For example on a rails route:
 * foo:bar:show
 * it tries to load:
 * ~/pages/foo/bar/show/index.js
 * ~/pages/foo/bar/index.js
 * ~/pages/foo/index.js
 *
 * if the JH/EE files exist, they take precendence over the CE file.
 *
 * If the file doesn't exist, it loads an empty JS file.
 *
 * Entries whose name ends with `.vue3` are sibling variants emitted by
 * `generateEntries` for pages with `status: rollout` in their
 * `vue3_migration.yml`. The leaf import gets `?vue3` appended so the
 * Vue 3 infection plugin's resolveId hook picks it up at the entry
 * boundary and propagates infection through the dependency graph.
 * Pages with `status: migrated` keep their original entry name but their
 * paths arrive from `generateEntries` already carrying the `?vue3`
 * marker (`appendVue3Query` is a no-op on them).
 */
export function PageEntrypointsPlugin() {
  const comment = '/* this is a virtual module used by Vite, it exists only in dev mode */\n';
  // Vite serves the global bundles straight from `entrypoints/` (see
  // `entrypointsDir` in `config/vite.json`). Only the entries the migration
  // changed need a virtual module: a `.vue3` sibling, or a `migrated` bundle
  // whose own key now points at the `?vue3` build. Page entries need one either way.
  const migrations = loadVue3Migrations();
  const globalVue3Entries = Object.fromEntries(
    Object.entries(applyVue3Migrations(baseEntryPoints, { migrations })).filter(
      ([entryName, modulePath]) => baseEntryPoints[entryName] !== modulePath,
    ),
  );
  const entrypoints = Object.entries({
    ...generateEntries([], { migrations }).entries,
    ...globalVue3Entries,
  }).reduce((acc, [entryName, imports]) => {
    const modulePaths = Array.isArray(imports) ? imports : [imports];
    const modulePath = modulePaths[modulePaths.length - 1];
    const importPath = modulePath.startsWith('./') ? `~/${modulePath.substring(2)}` : modulePath;
    const isVue3Variant = entryName.endsWith('.vue3');
    const entryImport = isVue3Variant ? appendVue3Query(importPath) : importPath;
    acc[`${entryName}.js`] = {
      virtual: `${comment}/* ${modulePath} */ import '${entryImport}';\n`,
      actual: `${entryImport.replace('~/', `${actualDirRoot}/`)}`,
    };
    return acc;
  }, {});

  const inputOptions = Object.keys(entrypoints).reduce((acc, key) => {
    acc[key.replace('.js', '')] = entrypoints[key].actual;
    return acc;
  }, {});

  return {
    name: 'vite-plugin-page-entrypoints',
    config() {
      return {
        build: {
          rolldownOptions: {
            input: inputOptions,
          },
        },
      };
    },
    // Vite dev server can not recognize entrypoint names from the URL
    // so we create a virtual file that imports the real entrypoint file
    load(id) {
      // Virtual entry ids are bare entry names. Anything with a separator is a
      // real module and belongs to Vite.
      if (id.includes('/')) {
        return undefined;
      }

      if (entrypoints[id]) {
        return entrypoints[id].virtual;
      }

      // Rails asks for every ancestor route segment, so most misses are
      // expected. A `.vue3` miss is not: Rails only asks for one when the
      // entry's feature flag is on, and an empty module would leave the page
      // with no Vue app and nothing in the console to say why.
      if (id.endsWith('.vue3.js')) {
        return `${comment}throw new Error(${JSON.stringify(
          `No Vue 3 entrypoint was built for ${id}. Restart the Vite dev server to pick up vue3_migration.yml changes.`,
        )});\n`;
      }

      if (id.startsWith('pages.')) {
        return `/* doesn't exist */`;
      }

      return undefined;
    },
    resolveId(source) {
      if (!source.startsWith(entrypointsDir)) {
        return undefined;
      }

      const id = source.slice(entrypointsDir.length);
      // Page entries are always virtual. Global bundles only are when a migration
      // changed them; the rest resolve to their file on disk.
      if (id.startsWith('pages.') || entrypoints[id]) {
        return { id };
      }

      return undefined;
    },
  };
}
