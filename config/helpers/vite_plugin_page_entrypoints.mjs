import path from 'node:path';
import { createRequire } from 'node:module';
import { generateEntries } from '../webpack.helpers';

const require = createRequire(import.meta.url);
const { appendVue3Query } = require('./vue3_migration_loader');

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
  const entrypoints = Object.entries(generateEntries().entries).reduce(
    (acc, [entryName, imports]) => {
      const modulePath = imports[imports.length - 1];
      const importPath = modulePath.startsWith('./') ? `~/${modulePath.substring(2)}` : modulePath;
      const isVue3Variant = entryName.endsWith('.vue3');
      const entryImport = isVue3Variant ? appendVue3Query(importPath) : importPath;
      acc[`${entryName}.js`] = {
        virtual: `${comment}/* ${modulePath} */ import '${entryImport}';\n`,
        actual: `${entryImport.replace('~/', `${actualDirRoot}/`)}`,
      };
      return acc;
    },
    {},
  );

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
      if (!id.startsWith('pages.')) {
        return undefined;
      }

      if (entrypoints[id]) {
        return entrypoints[id].virtual;
      }

      // Rails asks for every ancestor route segment, so most misses are
      // expected. A `.vue3` miss is not: Rails only asks for one when the
      // page's feature flag is on, and an empty module would leave the page
      // with no Vue app and nothing in the console to say why.
      if (id.endsWith('.vue3.js')) {
        return `${comment}throw new Error(${JSON.stringify(
          `No Vue 3 entrypoint was built for ${id}. Restart the Vite dev server to pick up vue3_migration.yml changes.`,
        )});\n`;
      }

      return `/* doesn't exist */`;
    },
    resolveId(source) {
      if (!source.startsWith(`${entrypointsDir}pages.`)) {
        return undefined;
      }
      return { id: source.replace(entrypointsDir, '') };
    },
  };
}
