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

  const stylesheetDir = '/stylesheets/';

  const styles = resolveCompilationTargetsForVite();

  const inputOptions = {};

  Object.entries(styles).forEach(([source, importPath]) => {
    inputOptions[`styles.${source}`] = importPath;
    inputOptions[`stylesheets/styles.${source}`] = importPath;
  });

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
            input: inputOptions,
          },
        },
      };
    },
    load(id) {
      if (!id.startsWith('styles.')) {
        return undefined;
      }
      const fixedId = id.replace('styles.', '').replace('.scss', '.css').replace(/\?.+/, '');

      if (fixedId === 'tailwind.css') {
        return `@import '${path.join(ROOT_PATH, 'app/assets/builds/tailwind.css')}';`;
      }

      return styles[fixedId] ? `@import '${styles[fixedId]}';` : '// Does not exist';
    },
    resolveId(source) {
      if (!source.startsWith(`${stylesheetDir}styles.`)) {
        return undefined;
      }
      return { id: source.replace(stylesheetDir, '') };
    },
  };
}
