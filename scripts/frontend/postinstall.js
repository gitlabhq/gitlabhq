const fs = require('fs');
const path = require('path');
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
      `)
    );
    process.exit(1);
  }
}

if (process.env.NODE_ENV !== 'production') {
  const lockfileParser = require('@yarnpkg/lockfile');

  // check that certain packages are only listed once in the yarn.lock
  const packagesToCheck = ['@gitlab-org/gitlab-svgs', 'bootstrap'];
  const file = fs.readFileSync(path.join(__dirname, '../../yarn.lock'), 'utf8');
  const packages = lockfileParser.parse(file);

  if (packages.type !== 'success') {
    console.error(`${chalk.red('error')} Could not parse 'yarn.lock'. Please make sure it exists`);
    process.exit(1);
  }

  function checkUniqueYarnLockEntry(hasError, packageName) {
    const resolved = Object.entries(packages.object).reduce((result, [name, value]) => {
      if (name.replace(/"/g, '').startsWith(`${packageName}@`)) {
        const resolvedUrl = value.resolved;

        if (!result.includes(resolvedUrl)) {
          result.push(resolvedUrl);
        }
      }
      return result;
    }, []);

    if (resolved.length !== 1) {
      console.error(
        chalk.red(`
        The dependency ${packageName} has ${resolved.length} entries in 'yarn.lock'.
        It is supposed to have exactly one entry, please fix that by:

           1. Delete all lines starting with '${packageName}@' from the yarn.lock
           2. Re-run \`${chalk.cyan('yarn install')}\`
           3. Commit changes to yarn.lock
      `)
      );
      return true;
    }

    return hasError;
  }

  const hasError = packagesToCheck.reduce(checkUniqueYarnLockEntry, false);

  if (hasError) {
    console.error(`${chalk.red('error')} Dependency postinstall check failed.`);
    process.exit(1);
  }
}

console.log(`${chalk.green('success')} Dependency postinstall check passed.`);
