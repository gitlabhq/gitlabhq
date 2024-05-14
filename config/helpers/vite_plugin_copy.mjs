import path from 'node:path';
import { copyFile, mkdir, stat } from 'node:fs/promises';
import globby from 'globby';

/**
 * This is a simple-reimplementation of the copy-webpack-plugin
 *
 * it also uses the `globby` package under the hood, and _only_ allows for copying
 * 1. absolute paths
 * 2. files and directories.
 */
export function CopyPlugin({ patterns }) {
  return {
    name: 'vite-plugin-copy',
    async configureServer() {
      console.warn('Start copying files...');
      let count = 0;

      const allTheFiles = patterns.map(async (patternEntry) => {
        const { from, to, globOptions = {} } = patternEntry;

        // By only supporting absolute paths we simplify
        // the implementation a lot
        if (!path.isAbsolute(from)) {
          throw new Error(`'from' path is not absolute: ${path}`);
        }
        if (!path.isAbsolute(to)) {
          throw new Error(`'to' path is not absolute: ${path}`);
        }

        let pattern = '';
        let sourceRoot = '';
        const fromStat = await stat(from);
        if (fromStat.isDirectory()) {
          sourceRoot = from;
          pattern = path.join(from, '**/*');
        } else if (fromStat.isFile()) {
          sourceRoot = path.dirname(from);
          pattern = from;
        } else {
          // No need to support globs, because we do not
          // use them yet...
          throw new Error('Our implementation does not support globs.');
        }

        globOptions.dot = globOptions.dot ?? true;

        const paths = await globby(pattern, globOptions);

        return paths.map((srcPath) => {
          const targetPath = path.join(to, path.relative(sourceRoot, srcPath));
          return { srcPath, targetPath };
        });
      });

      const srcTargetMap = (await Promise.all(allTheFiles)).flat();

      await Promise.all(
        srcTargetMap.map(async ({ srcPath, targetPath }) => {
          try {
            await mkdir(path.dirname(targetPath), { recursive: true });
            await copyFile(srcPath, targetPath);
            count += 1;
          } catch (e) {
            console.warn(`Could not copy ${srcPath} => ${targetPath}`);
          }
        }),
      );

      console.warn(`Done copying ${count} files...`);
    },
  };
}
