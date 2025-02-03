const { spawnSync } = require('child_process');
const { join } = require('path');
const { readFileSync, existsSync } = require('fs');
const chalk = require('chalk');
const semver = require('semver');

// Check duo-ui peer dependency
function checkDuoUiPeerDependency() {
  try {
    const duoUiPkgPath = join('node_modules', '@gitlab', 'duo-ui', 'package.json');

    if (!existsSync(duoUiPkgPath)) {
      console.error(`${chalk.red('error')} Could not find @gitlab/duo-ui package.json`);
      return false;
    }

    const packageJson = JSON.parse(readFileSync('package.json', 'utf8'));
    const duoUiPkgJson = JSON.parse(readFileSync(duoUiPkgPath, 'utf8'));

    const installedUiVersion = packageJson.dependencies['@gitlab/ui'];
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

// Apply any patches to our packages
// See https://gitlab.com/gitlab-org/gitlab/-/issues/336138
process.exitCode =
  spawnSync('node_modules/.bin/patch-package', ['--error-on-fail', '--error-on-warn'], {
    stdio: ['ignore', 'inherit', 'inherit'],
  }).status ?? 1;
