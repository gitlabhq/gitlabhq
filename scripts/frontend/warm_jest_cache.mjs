#!/usr/bin/env node

import { join, relative } from 'node:path';
import { spawnSync } from 'node:child_process';
import { writeFile, rename, rm, mkdir } from 'node:fs/promises';
import chalk from 'chalk';
import pkg from 'glob';

const { glob } = pkg;
const rootPath = join(import.meta.dirname, '..', '..');
const testPath = join(rootPath, 'spec/frontend/_warm_cache');
const maxTestPerFile = 50;
let currentTestFile = 0;

function findFiles() {
  return glob
    .sync('{jh,ee/,}app/assets/javascripts/**/*.{js,vue,graphql}', {
      cwd: rootPath,
      ignore: [
        // Try to avoid side effects and unparseable files (e.g., node modules
        // we don't transpile for Jest, like mermaid) by excluding files we
        // normally wouldn't write specs for.
        //
        // The most correct way to do this would be to parse all our spec files
        // and import all files *they* import, but that's a lot more effort.
        '**/app/assets/javascripts/main{_ee,_jh,}.js',
        '**/app/assets/javascripts/{behaviors,pages,entrypoints}/**/*',
        // A dev-only file
        '**/app/assets/javascripts/webpack_non_compiled_placeholder.js',

        // Generated translation files
        '**/app/assets/javascripts/locale/*/app.js',
        // Storybook stories
        '**/*.stories.js',

        // This file imports the `mermaid` node module, which is written in ES
        // module format, and Jest isn't configured to transpile it. It's
        // surprising that we don't have any specs that even transitively
        // import mermaid.
        '**/app/assets/javascripts/lib/mermaid.js',

        // These *should* be in /pages/ 🤷
        '**/app/assets/javascripts/snippet/snippet_show.js',
        '**/app/assets/javascripts/admin/application_settings/setup_metrics_and_profiling.js',

        // # Thse ones have a problem with jQuery.ajaxPrefilter not being defined
        'app/assets/javascripts/lib/utils/rails_ujs.js',
        'app/assets/javascripts/profile/profile.js',
        'app/assets/javascripts/namespaces/leave_by_url.js',
        // # These ones aren't working for some reason or another,
        'app/assets/javascripts/blob/stl_viewer.js',
        'app/assets/javascripts/blob/3d_viewer/index.js',
        'app/assets/javascripts/filtered_search/**/*',
      ],
    })
    .sort();
}

async function writeTestFile(arr) {
  currentTestFile += 1;
  const data = `${arr.join('\n')}

it('nothing', () => { expect(1).toBe(1); })
`;
  const baseName = `${currentTestFile}`.padStart(3, '0');
  return writeFile(join(testPath, `${baseName}_spec.js`), data);
}

function setExitCode(statusOrError) {
  // No error, do nothing.
  if (statusOrError === 0) return;

  if (process.env.CI) {
    if (process.env.CI_MERGE_REQUEST_IID) {
      // In merge requests, fail the pipeline by setting the exit code to
      // something other than the allowed failure value.
      process.exitCode = 2;
    } else {
      // In master and other pipelines, set it to the allowed exit code.
      process.exitCode = 1;
    }
  } else {
    // Not in CI, pass through status as-is
    process.exitCode = typeof statusOrError === 'number' ? statusOrError : 1;
  }
}

async function main() {
  let curr = [];

  await mkdir(testPath, { recursive: true });

  const files = findFiles();

  for (const item of files) {
    const transformedPath = item
      .replace(/^app\/assets\/javascripts\//, '~/')
      .replace(/^(ee|jh)\/app\/assets\/javascripts\//, '$1/')
      .replace(/\.js$/, '');

    if (curr.length >= maxTestPerFile) {
      // eslint-disable-next-line no-await-in-loop
      await writeTestFile(curr);
      curr = [];
    }

    curr.push(`import '${transformedPath}';`);
  }

  await writeTestFile(curr);

  console.log(`[WARMING JEST]: Start execution`);

  const result = spawnSync('yarn', ['run', 'jest', testPath], {
    cwd: rootPath,
    detached: true,
    stdio: 'inherit',
  });

  console.log(`[WARMING JEST]: End execution: jest exited with ${result.status}`);

  if (process.env.CI) {
    console.log(`Moving spec/frontend/_warm_cache to tmp/`);
    await rename(testPath, join(rootPath, 'tmp/cache/jest/_warm_cache'));
  } else {
    console.log(`Removing spec/frontend/_warm_cache`);
    await rm(testPath, { recursive: true, force: true });
  }

  if (result.status !== 0) {
    const scriptPath = relative(rootPath, import.meta.filename);
    console.log(chalk.red('Jest cache warming failed!'));
    console.log(
      chalk.red(
        `If the failure is due to an import error, add the problematic file(s) to the ignore list in ${scriptPath}.`,
      ),
    );
    console.log(chalk.red('For help, contact the Manage:Foundations team.'));
  }

  return result.status;
}

try {
  setExitCode(await main());
} catch (error) {
  setExitCode(error);
  console.error(error);
}
