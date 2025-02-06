import { generateEntries } from '../webpack.helpers';

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
  const comment = '/* this is a virtual module used by Vite, it exists only in dev mode */\n';
  const entrypoints = Object.entries(generateEntries()).reduce((acc, [entryName, imports]) => {
    const modulePath = imports[imports.length - 1];
    const importPath = modulePath.startsWith('./') ? `~/${modulePath.substring(2)}` : modulePath;
    acc[`${entryName}.js`] = {
      virtual: `${comment}/* ${modulePath} */ import '${importPath}';\n`,
      actual: `${importPath.replace('~/', './app/assets/javascripts/')}`,
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
          rollupOptions: {
            input: inputOptions,
          },
        },
      };
    },
    load(id) {
      if (!id.startsWith('pages.')) {
        return undefined;
      }
      return entrypoints[id]?.virtual ?? `/* doesn't exist */`;
    },
    resolveId(source) {
      if (!source.startsWith(`${entrypointsDir}pages.`)) {
        return undefined;
      }
      return { id: source.replace(entrypointsDir, '') };
    },
  };
}
