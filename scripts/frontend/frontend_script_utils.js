const execFileSync = require('child_process').execFileSync;

const exec = (command, args) => {
  const options = {
    cwd: process.cwd(),
    env: process.env,
    encoding: 'utf-8',
  };
  return execFileSync(command, args, options);
};

const execGitCmd = args =>
  exec('git', args)
    .trim()
    .toString()
    .split('\n');

module.exports = {
  getStagedFiles: fileExtensionFilter => {
    const gitOptions = ['diff', '--name-only', '--cached', '--diff-filter=ACMRTUB'];
    if (fileExtensionFilter) gitOptions.push(...fileExtensionFilter);
    return execGitCmd(gitOptions);
  },
};
