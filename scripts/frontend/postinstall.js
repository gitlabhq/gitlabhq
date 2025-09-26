/* eslint-disable global-require, import/no-dynamic-require */
const { spawnSync, execSync } = require('child_process');
const { join, resolve } = require('path');
const { existsSync } = require('fs');
const { env } = require('process');
const chalk = require('chalk');
const semver = require('semver');

const ROOT_PATH = resolve(__dirname, '../../');

function frozenRequestedFromEnv() {
  // Yarn/NPM expose the original CLI args here (as JSON)
  const raw = process.env.npm_config_argv;
  if (raw) {
    try {
      const parsed = JSON.parse(raw);
      const orig = Array.isArray(parsed.original) ? parsed.original : [];
      if (orig.includes('--frozen-lockfile') || orig.includes('--pure-lockfile')) {
        return true;
      }
    } catch {
      // ignore parse errors; fall through to other checks
    }
  }
  // Some environments also set this as a boolean-ish var
  if (
    process.env.npm_config_frozen_lockfile === 'true' ||
    process.env.npm_config_frozen_lockfile === '1'
  ) {
    return true;
  }
  return false;
}

// Check duo-ui peer dependency
function checkDuoUiPeerDependency() {
  try {
    const duoUiPkgPath = join(ROOT_PATH, 'node_modules', '@gitlab', 'duo-ui', 'package.json');
    const gitlabUiPkgPath = join(ROOT_PATH, 'node_modules', '@gitlab', 'ui', 'package.json');

    if (!existsSync(duoUiPkgPath)) {
      console.error(`${chalk.red('error')} Could not find @gitlab/duo-ui package.json`);
      return false;
    }

    const packageJson = require(gitlabUiPkgPath);
    const duoUiPkgJson = require(duoUiPkgPath);

    const installedUiVersion = packageJson.version;
    const requiredUiVersion = duoUiPkgJson.peerDependencies?.['@gitlab/ui'];

    if (!installedUiVersion) {
      console.error(`${chalk.red('error')} @gitlab/ui is not installed`);
      return false;
    }

    if (!requiredUiVersion) {
      console.error(
        `${chalk.red('error')} @gitlab/duo-ui does not specify @gitlab/ui peer dependency`,
      );
      return false;
    }

    if (!semver.satisfies(installedUiVersion, requiredUiVersion)) {
      console.error(`${chalk.red('error')} Peer dependency violation:`);
      console.error(
        chalk.red(
          `@gitlab/duo-ui requires @gitlab/ui@${requiredUiVersion} but ${installedUiVersion} is installed`,
        ),
      );
      return false;
    }

    return true;
  } catch (error) {
    console.error(`${chalk.red('error')} Failed to check duo-ui peer dependency:`, error.message);
    return false;
  }
}

/**
 * Installs dependencies for a Vue 3 "frontend island" project using Yarn.
 *
 * This function:
 * - Verifies that the target folder contains a `package.json`
 * - Runs `yarn install` inside that folder
 * - Adds `--frozen-lockfile` if the root install was run with that flag
 * - Logs progress to the console
 *
 * @param {string} relativePath - Path to the frontend island project, relative to the repository root.
 * @returns {boolean} Returns `true` if installation was performed, or `false` if no `package.json` was found.
 *
 * @throws {Error} If `yarn install` fails, `execSync` will propagate the error.
 */
function installFEIslandIfPresent(relativePath) {
  const abs = join(ROOT_PATH, relativePath);
  const pkg = join(abs, 'package.json');

  if (!existsSync(pkg)) {
    console.log(`${chalk.red('error')} Could not find package.json in ${relativePath}`);
    return false;
  }

  const args = ['install'];
  if (frozenRequestedFromEnv()) args.push('--frozen-lockfile');

  console.log(`Installing ${relativePath} with yarn ${args.join(' ')}`);
  execSync(`yarn ${args.join(' ')}`, {
    cwd: abs,
    stdio: 'inherit',
  });
  console.log(`${chalk.green('success')} Installed ${relativePath}`);

  return true; // satisfy consistent-return
}

['ee/frontend_islands/apps/duo_next'].forEach(installFEIslandIfPresent);

// check that fsevents is available if we're on macOS
if (process.platform === 'darwin') {
  try {
    require.resolve('fsevents');
  } catch (e) {
    console.error(`${chalk.red('error')} Dependency postinstall check failed.`);
    console.error(
      chalk.red(
        `The fsevents driver is not installed properly.
        If you are running a new version of Node, please
        ensure that it is supported by the fsevents library.

        You can try installing again with \`${chalk.cyan('yarn install --force')}\`
      `,
      ),
    );
    process.exit(1);
  }
}

// Check duo-ui peer dependency
if (!checkDuoUiPeerDependency()) {
  process.exit(1);
}

console.log(`${chalk.green('success')} Dependency postinstall check passed.`);

// skip patching when populating cache on CI to not change file metadata and allow install commands to re-apply patch
// if patch files are ever updated
if (env.GLCI_SKIP_NODE_MODULES_PATCHING !== 'true') {
  // Apply any patches to our packages
  // See https://gitlab.com/gitlab-org/gitlab/-/issues/336138
  process.exitCode =
    spawnSync('node_modules/.bin/patch-package', ['--error-on-fail', '--error-on-warn'], {
      stdio: ['ignore', 'inherit', 'inherit'],
    }).status ?? 1;
}
