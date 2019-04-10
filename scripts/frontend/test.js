#!/usr/bin/env node

const program = require('commander');
const { spawn } = require('child_process');

const JEST_ROUTE = 'spec/frontend';
const KARMA_ROUTE = 'spec/javascripts';
const COMMON_ARGS = ['--colors'];

program
  .version('0.1.0')
  .usage('[options] <file ...>')
  .option('-p, --parallel', 'Run tests suites in parallel')
  .parse(process.argv);

const runTests = paths => {
  if (program.parallel) {
    return Promise.all([runJest(paths), runKarma(paths)]);
  } else {
    return runJest(paths).then(() => runKarma(paths));
  }
};

const spawnPromise = (cmd, args) => {
  return new Promise((resolve, reject) => {
    const proc = spawn('yarn', ['run', cmd, ...args]);
    const output = data => `${cmd}: ${data}`;

    proc.stdout.on('data', data => {
      process.stdout.write(output(data));
    });

    proc.stderr.on('data', data => {
      process.stderr.write(output(data));
    });

    proc.on('close', code => {
      process.stdout.write(`${cmd} exited with code ${code}`);
      if (code === 0) {
        resolve();
      } else {
        reject();
      }
    });
  });
};

const runJest = args => {
  return spawnPromise('jest', [...COMMON_ARGS, ...toJestArgs(args)]);
};

const runKarma = args => {
  return spawnPromise('karma', [...COMMON_ARGS, ...toKarmaArgs(args)]);
};

const replacePath = to => path =>
  path
    .replace(JEST_ROUTE, to)
    .replace(KARMA_ROUTE, to)
    .replace('app/assets/javascripts', to);

const toJestArgs = paths => paths.map(replacePath(JEST_ROUTE));

const toKarmaArgs = paths =>
  paths.map(replacePath(KARMA_ROUTE)).reduce((acc, current) => acc.concat('-f', current), []);

const main = paths => {
  runTests(paths)
    .then(() => {
      console.log('All tests passed!');
    })
    .catch(() => {
      console.log('Some tests failed...');
    });
};

main(program.args);
