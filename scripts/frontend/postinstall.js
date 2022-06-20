const { execSync } = require('child_process');
const chalk = require('chalk');

// check that fsevents is available if we're on macOS
if (process.platform === 'darwin') {
  try {
    require.resolve('fsevents');
  } catch (e) {
    console.error(`${chalk.red('error')} Dependency postinstall check failed.`);
    console.error(
      chalk.red(`
        The fsevents driver is not installed properly.
        If you are running a new version of Node, please
        ensure that it is supported by the fsevents library.

        You can try installing again with \`${chalk.cyan('yarn install --force')}\`
      `),
    );
    process.exit(1);
  }
}

console.log(`${chalk.green('success')} Dependency postinstall check passed.`);

// Apply any patches to our packages
// See https://gitlab.com/gitlab-org/gitlab/-/issues/336138
execSync('node_modules/.bin/patch-package --error-on-fail');
console.log(`${chalk.green('success')} Packages successfully patched.`);
