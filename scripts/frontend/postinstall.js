/* eslint-disable global-require, import/no-dynamic-require */
const { spawnSync } = require('child_process');
const { join, resolve } = require('path');
const { existsSync } = require('fs');
const { env } = require('process');
const chalk = require('chalk');
const semver = require('semver');

const ROOT_PATH = resolve(__dirname, '../../');

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
