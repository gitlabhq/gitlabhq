#!/usr/bin/env node

import { argv, cwd } from 'node:process';
import { join, resolve, relative, dirname } from 'node:path';
import { mkdir, stat, readFile, writeFile } from 'node:fs/promises';
import glob from 'glob';
import * as esbuild from 'esbuild';
import * as prettier from 'prettier';

/**
 * VISION: This script could be made more generalizable, to be able to
 * "normalize" our complete asset folder in order to easily diff them.
 *
 * It might even be great to have support for using MRs/Pipelines, etc.
 *
 * normalize_assets.mjs https://gitlab.com/gitlab-org/gitlab/-/pipelines/1143467234 tmp/current_master
 * normalize_assets.mjs https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140611 tmp/after_change
 */

/**
 * 1. this function removes the `hash` from the file name
 *   (sprockets is unhappy compiling without hash)
 * 2. Minifies the css, to remove comments and normalize things like
 *   `#ffffff` and `#fff` or `.5rem` and `0.5rem`
 * 3. Prettifies it again, to make it diffable
 */
async function cleanUpCSSFile(sourceFile, sourceDir, targetDir) {
  const targetFile = join(targetDir, relative(sourceDir, sourceFile)).replace(
    /-[a-f0-9]{20,}.css$/,
    '.css',
  );
  await mkdir(dirname(targetFile), { recursive: true });

  const content = await readFile(sourceFile, 'utf-8');
  const minified = await esbuild.transform(content, {
    minify: true,
    loader: 'css',
  });
  const pretty = await prettier.format(minified.code, { parser: 'css' });
  console.log(`Copied ${relative(cwd(), sourceFile)} to \n\t${relative(cwd(), targetFile)}`);
  return writeFile(targetFile, pretty, 'utf-8');
}

async function main() {
  const [, , sourceDirRel, targetDirRel] = argv;

  if (!sourceDirRel || !targetDirRel) {
    throw new Error('Please start this script like with two parameters: <sourcePath> <targetPath>');
  }

  const sourceDir = resolve(cwd(), sourceDirRel);

  const s = await stat(sourceDir);
  if (!s.isDirectory()) {
    throw new Error(`sourcePath ${sourceDir} is not a directory`);
  }

  const targetDir = resolve(cwd(), targetDirRel);

  const cssFiles = glob.sync(join(sourceDir, '**/*.css'));

  return Promise.all(
    cssFiles.map((sourceFile) => cleanUpCSSFile(sourceFile, sourceDir, targetDir)),
  );
}

try {
  await main();
} catch (e) {
  console.error(e);
  process.exitCode = 1;
}
