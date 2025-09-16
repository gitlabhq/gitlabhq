import path from 'node:path';
import {
  resolveCompilationTargetsForVite,
  resolveLoadPaths,
} from '../../scripts/frontend/lib/compile_css.mjs';

const ROOT_PATH = path.resolve(import.meta.dirname, '../../');

/**
 * This Plugin provides virtual entrypoints for our SCSS files
 *
 * For example with an import like:
 *    universal_stylesheet_link_tag "application"
 * it will try to load and compile
 *    app/assets/stylesheets/application.scss
 *
 * if the JH/EE variant exist, they take precendence over the CE file, so
 *   add_page_specific_style 'page_bundles/boards'
 * will load:
 *   ee/app/assets/stylesheets/page_bundles/boards.scss in EE
 *   app/assets/stylesheets/page_bundles/boards.scss in CE
 *
 * If the file doesn't exist, it loads an empty SCSS file.
 */
export function StylePlugin({ shouldWatch = false } = {}) {
  const imagesPath = path.resolve(ROOT_PATH, 'app/assets/images');
  const eeImagesPath = path.resolve(ROOT_PATH, 'ee/app/assets/images');
  const jhImagesPath = path.resolve(ROOT_PATH, 'jh/app/assets/images');

  const entrypoints = {
    'styles/tailwind.css': path.join(ROOT_PATH, 'app/assets/builds/tailwind.css'),
    'styles/tailwind_cqs.css': path.join(ROOT_PATH, 'app/assets/builds/tailwind_cqs.css'),
    ...Object.fromEntries(
      Object.entries(resolveCompilationTargetsForVite()).map(([key, value]) => {
        // we must add `styles/` because ViteRuby prepends assets folder to the request if `/` is missing
        return [`styles/${key}`, value];
      }),
    ),
  };

  return {
    name: 'vite-plugin-style',
    config() {
      return {
        css: {
          preprocessorOptions: {
            scss: {
              sourceMap: shouldWatch,
              sourceMapEmbed: shouldWatch,
              sourceMapContents: shouldWatch,
              loadPaths: [...resolveLoadPaths(), imagesPath, eeImagesPath, jhImagesPath],
            },
          },
        },
        build: {
          rollupOptions: {
            input: entrypoints,
          },
        },
      };
    },
    // Vite dev server can not recognize entrypoint names from the URL
    // so we create a virtual file that imports the real entrypoint file
    load(id) {
      if (!id.startsWith('/styles/')) return;
      const entrypointName = id.substring(1).replace(/\?.+/, '');
      const resolvedPath = entrypoints[entrypointName];
      // eslint-disable-next-line consistent-return
      if (resolvedPath) return `@import '${resolvedPath}';`;
    },
  };
}
