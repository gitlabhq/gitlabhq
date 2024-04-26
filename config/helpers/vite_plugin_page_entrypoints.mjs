import { generateEntries } from '../webpack.helpers';

const comment = '/* this is a virtual module used by Vite, it exists only in dev mode */\n';
export const virtualEntrypoints = Object.entries(generateEntries()).reduce(
  (acc, [entryName, imports]) => {
    const modulePath = imports[imports.length - 1];
    const importPath = modulePath.startsWith('./') ? `~/${modulePath.substring(2)}` : modulePath;
    acc[`${entryName}.js`] = `${comment}/* ${modulePath} */ import '${importPath}';\n`;
    return acc;
  },
  {},
);

const entrypointsDir = '/javascripts/entrypoints/';

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
 */
export function PageEntrypointsPlugin() {
  return {
    name: 'vite-plugin-page-entrypoints',
    load(id) {
      if (!id.startsWith('pages.')) {
        return undefined;
      }
      return virtualEntrypoints[id] ?? `/* doesn't exist */`;
    },
    resolveId(source) {
      const fixedSource = source.replace(entrypointsDir, '');
      if (fixedSource.startsWith('pages.')) return { id: fixedSource };
      return undefined;
    },
  };
}
