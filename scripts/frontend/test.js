#!/usr/bin/env node

const { spawn } = require('child_process');
const { EOL } = require('os');
const program = require('commander');
const chalk = require('chalk');

const SUCCESS_CODE = 0;
const JEST_ROUTE = 'spec/frontend';
const KARMA_ROUTE = 'spec/javascripts';
const COMMON_ARGS = ['--colors'];
const jestArgs = [...COMMON_ARGS, '--passWithNoTests'];
const karmaArgs = [...COMMON_ARGS, '--no-fail-on-empty-test-suite'];

program
  .usage('[options] <file ...>')
  .option('-p, --parallel', 'Run tests suites in parallel')
  .option(
    '-w, --watch',
    'Rerun tests when files change (tests will be run in parallel if this enabled)',
  )
  .parse(process.argv);

const shouldParallelize = program.parallel || program.watch;

const isSuccess = code => code === SUCCESS_CODE;

const combineExitCodes = codes => {
  const firstFail = codes.find(x => !isSuccess(x));

  return firstFail === undefined ? SUCCESS_CODE : firstFail;
};

const skipIfFail = fn => code => (isSuccess(code) ? fn() : code);

const endWithEOL = str => (str[str.length - 1] === '\n' ? str : `${str}${EOL}`);

const runTests = paths => {
  if (shouldParallelize) {
    return Promise.all([runJest(paths), runKarma(paths)]).then(combineExitCodes);
  } else {
    return runJest(paths).then(skipIfFail(() => runKarma(paths)));
  }
};

const spawnYarnScript = (cmd, args) => {
  return new Promise((resolve, reject) => {
    const proc = spawn('yarn', ['run', cmd, ...args]);
    const output = data => {
      const text = data
        .toString()
        .split(/\r?\n/g)
        .map((line, idx, { length }) =>
          idx === length - 1 && !line ? line : `${chalk.gray(cmd)}: ${line}`,
        )
        .join(EOL);

      return endWithEOL(text);
    };

    proc.stdout.on('data', data => {
      process.stdout.write(output(data));
    });

    proc.stderr.on('data', data => {
      process.stderr.write(output(data));
    });

    proc.on('close', code => {
      process.stdout.write(output(`exited with code ${code}`));

      // We resolve even on a failure code because a `reject` would cause
      // Promise.all to reject immediately (without waiting for other promises)
      // to finish.
      resolve(code);
    });
  });
};

const runJest = args => {
  return spawnYarnScript('jest', [...jestArgs, ...toJestArgs(args)]);
};

const runKarma = args => {
  return spawnYarnScript('karma', [...karmaArgs, ...toKarmaArgs(args)]);
};

const replacePath = to => path =>
  path
    .replace(JEST_ROUTE, to)
    .replace(KARMA_ROUTE, to)
    .replace('app/assets/javascripts', to);

const replacePathForJest = replacePath(JEST_ROUTE);

const replacePathForKarma = replacePath(KARMA_ROUTE);

const toJestArgs = paths => paths.map(replacePathForJest);

const toKarmaArgs = paths =>
  paths.reduce((acc, path) => acc.concat('-f', replacePathForKarma(path)), []);

const main = paths => {
  if (program.watch) {
    jestArgs.push('--watch');
    karmaArgs.push('--single-run', 'false', '--auto-watch');
  }
  runTests(paths).then(code => {
    console.log('~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~');
    if (isSuccess(code)) {
      console.log(chalk.bgGreen(chalk.black('All tests passed :)')));
    } else {
      console.log(chalk.bgRed(chalk.white(`Some tests failed :(`)));
    }
    console.log('~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~');

    if (!isSuccess(code)) {
      process.exit(code);
    }
  });
};

main(program.args);
