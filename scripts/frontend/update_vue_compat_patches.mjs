#!/usr/bin/env node

import { existsSync, mkdirSync, readFileSync, rmSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { spawnSync } from 'node:child_process';
import { createInterface } from 'node:readline/promises';
import { stdin, stdout } from 'node:process';
import { styleText } from 'node:util';

const repoRoot = resolve(import.meta.dirname, '../..');

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------

const FORK_README = `https://gitlab.com/gitlab-org/frontend/vuejs-core/-/blob/latest-gitlab-hybrid/README.md`;

const OVERVIEW = `\
This script guides you through regenerating the GitLab @vue/compat patches.

It will:

  1. read the @vue/compat version from the current package.json,
  2. create a temporary clone of our vuejs-core fork and regenerate the patches
     for that version,
  3. update our vuejs-core fork at
     https://gitlab.com/gitlab-org/frontend/vuejs-core, and
  4. ask you to commit and push the patches to the gitlab-org/gitlab branch and
     wait for CI to pass.

This script handles the happy path only. If a step needs manual intervention,
(rebase conflicts, a missing upstream tag, patches that do not apply, patches
do not pass in CI), follow the manual process described in
${FORK_README}

If in doubt, ask in #vue3_migration on Slack.

Prerequisites:
  - Your git credentials can push to the vuejs-core fork.
  - node and corepack are on your PATH.
`;

const GITLAB_HOST = 'gitlab.com';
const VUEJS_CORE_PROJECT = 'gitlab-org/frontend/vuejs-core';

// Branch in the vuejs-core fork that tracks the latest patch series.
const LATEST_HYBRID_BRANCH = 'latest-gitlab-hybrid';

// Directory (relative to repo root) holding patch-package patches.
const PATCHES_DIR = 'patches';

// Where the fork clone is created.
const TMP_DIR = join(repoRoot, 'tmp');
const VUE_DIR = join(TMP_DIR, 'vuejs-core');

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/**
 * Run a command in `cwd` with inherited stdio (output streams to the terminal)
 * and return the spawnSync result. Throws on a non-zero exit unless
 * `throwOnFailure: false`.
 */
function run(command, commandArgs, { cwd, throwOnFailure = true } = {}) {
  const result = spawnSync(command, commandArgs, { cwd, stdio: 'inherit' });
  if (result.error) {
    throw new Error(`Error trying to run ${command}: ${result.error.message}`);
  }
  if (throwOnFailure && result.status !== 0) {
    throw new Error(`${command} ${commandArgs.join(' ')} failed`);
  }
  return result;
}

/** Print a numbered step header, auto-incrementing the step number. */
let stepNumber = 0;
function step(title) {
  stepNumber += 1;
  console.log(styleText('bold', `\n=== Step ${stepNumber}: ${title} ===`));
}

/** Ask a yes/no question. An empty answer defaults to yes. */
async function confirm(question, { showOptions = true } = {}) {
  const rl = createInterface({ input: stdin, output: stdout });
  const options = showOptions ? ' [Y/n] ' : '';
  try {
    const answer = (await rl.question(`${question}${options}`)).trim().toLowerCase();
    return answer === '' || answer === 'y' || answer === 'yes';
  } finally {
    rl.close();
  }
}

/** Read the `@vue/compat` version this MR upgrades to from package.json. */
function readTargetVersion() {
  const pkg = JSON.parse(readFileSync(join(repoRoot, 'package.json'), 'utf8'));
  const version = pkg.dependencies?.['@vue/compat'];
  if (!version) {
    throw new Error('@vue/compat not found in package.json dependencies.');
  }
  if (!/^\d+\.\d+\.\d+$/.test(version)) {
    throw new Error(`Could not parse a version from @vue/compat version "${version}".`);
  }
  return version;
}

/** Clone the fork fresh into ./tmp, prompting to delete any existing clone. */
async function ensureForkClone() {
  const useSsh = await confirm('Clone over SSH? (no for HTTPS)');
  const url = useSsh
    ? `git@${GITLAB_HOST}:${VUEJS_CORE_PROJECT}.git`
    : `https://${GITLAB_HOST}/${VUEJS_CORE_PROJECT}.git`;
  if (existsSync(VUE_DIR)) {
    const remove = await confirm(`${VUE_DIR} already exists. Delete it and re-clone?`);
    if (!remove) {
      throw new Error(`Aborted. The existing clone at ${VUE_DIR} was left in place.`);
    }
    rmSync(VUE_DIR, { recursive: true, force: true });
  }
  mkdirSync(TMP_DIR, { recursive: true });
  console.log(`Cloning ${VUEJS_CORE_PROJECT} into ${VUE_DIR}...`);
  run('git', ['clone', '--tags', '--no-single-branch', url, VUE_DIR], { cwd: repoRoot });

  // Start from a known-clean copy of the hybrid branch.
  run('git', ['checkout', '-B', LATEST_HYBRID_BRANCH, `origin/${LATEST_HYBRID_BRANCH}`], {
    cwd: VUE_DIR,
  });
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main() {
  console.log(OVERVIEW);
  if (!(await confirm('Proceed?'))) {
    return;
  }

  step('Determine @vue/compat version');
  const version = readTargetVersion();
  const versionTag = `v${version}`;
  const branch = `${versionTag}-gitlab-hybrid`;
  console.log(`Detected @vue/compat version: ${version}`);

  // Get a clean copy of the fork to work in.
  step(`Prepare the ${VUEJS_CORE_PROJECT} clone`);
  await ensureForkClone();

  // If this version was already processed, offer to use that branch as-is.
  const branchExists =
    run('git', ['show-ref', '--verify', '--quiet', `refs/remotes/origin/${branch}`], {
      cwd: VUE_DIR,
      throwOnFailure: false,
    }).status === 0;
  if (branchExists) {
    console.log(`${branch} already exists on ${VUEJS_CORE_PROJECT}, using as-is.`);

    // Check out the already-processed branch and regenerate from it as-is.
    step(`Check out existing ${branch}`);
    run('git', ['checkout', '-B', branch, `origin/${branch}`], { cwd: VUE_DIR });
  } else {
    // Verify the upstream tag is mirrored into the fork.
    try {
      run('git', ['rev-parse', '--verify', `${versionTag}^{commit}`], { cwd: VUE_DIR });
    } catch {
      throw new Error(
        `Upstream tag ${versionTag} not found in ${VUEJS_CORE_PROJECT}. Is it mirrored yet?`,
      );
    }

    step(`Rebase ${branch} onto ${versionTag}`);
    run('git', ['checkout', '-B', branch, LATEST_HYBRID_BRANCH], { cwd: VUE_DIR });
    const rebase = run('git', ['rebase', '--no-update-refs', versionTag], {
      cwd: VUE_DIR,
      throwOnFailure: false,
    });
    if (rebase.status !== 0) {
      throw new Error(
        `Rebase of ${branch} onto ${versionTag} failed. Follow the manual process described in ${FORK_README}.\n\n` +
          `The conflicted rebase is left in ${VUE_DIR} for inspection.`,
      );
    }
  }

  step('Install vuejs-core dependencies');
  run('corepack', ['pnpm', 'install', '--frozen-lockfile'], { cwd: VUE_DIR });

  step(`Regenerate patches into ${PATCHES_DIR}/`);
  run(
    'node',
    [
      join('scripts', 'generate-gitlab-patches.js'),
      '--output',
      join(repoRoot, PATCHES_DIR),
      '--clean',
    ],
    { cwd: VUE_DIR },
  );

  step(`Update the ${VUEJS_CORE_PROJECT} branch pointers`);

  // When the branch already existed we reused it as-is, so there is nothing new
  // to write back to the fork.
  if (branchExists) {
    console.log(
      `Branch ${branch} already exists on ${VUEJS_CORE_PROJECT}, so the fork was not changed.`,
    );
  } else {
    console.log(
      `This will run the following against ${GITLAB_HOST}/${VUEJS_CORE_PROJECT} ` +
        `using your git credentials:\n\n` +
        `  git -C ${VUE_DIR} push --atomic --force-with-lease origin ${branch}:${branch} ${branch}:${LATEST_HYBRID_BRANCH}\n`,
    );
    run(
      'git',
      [
        'push',
        '--atomic',
        '--force-with-lease',
        'origin',
        `${branch}:${branch}`,
        `${branch}:${LATEST_HYBRID_BRANCH}`,
      ],
      { cwd: VUE_DIR },
    );
  }

  step('Commit and push');
  console.log(
    `Now commit and push the changes in ${PATCHES_DIR}/:\n\n` +
      `  git add ${PATCHES_DIR}\n` +
      `  git commit -m "Update @vue/compat patches for ${versionTag}"\n` +
      `  git push\n`,
  );

  await confirm('Press Enter once you have done so to proceed...', { showOptions: false });

  step('Wait for CI to pass');
  console.log(
    `Now wait for CI to run. If it passes, you're done. ` +
      `If not and you're not sure how to proceed, ask for help in #vue3_migration on Slack.`,
  );
}

main().catch((err) => {
  console.error(`\n${err.message || err}`);
  process.exitCode = 1;
});
