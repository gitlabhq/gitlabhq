const { spawn } = require('child_process');

const runEslint = () => {
  const [, , ...args] = process.argv;
  const child = spawn(`yarn`, ['internal:eslint', ...args], {
    stdio: 'inherit',
  });

  child.on('exit', (code) => {
    process.exitCode = code;

    if (code === 0) {
      return;
    }
    console.log(`
If you are seeing @graphql-eslint offences, the local GraphQL schema dump might be outdated.
Consider updating it by running \`./scripts/dump_graphql_schema\`.
    `);
  });
};

runEslint();
