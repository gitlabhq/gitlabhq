const { spawn } = require('child_process');

const showGraphQLLocalSchemaDumpMessage = () => {
  console.log(`
If you are seeing @graphql-eslint offences, the local GraphQL schema dump might be outdated.
Consider updating it by running \`./scripts/dump_graphql_schema\`.
    `);
};

const runEslint = () => {
  const args = process.argv.slice(2);
  const child = spawn(`yarn`, ['internal:eslint', ...args], {
    stdio: 'inherit',
    name: 'ESLint',
  });

  child.on('close', (code) => {
    process.exitCode = code;

    if (code === 0) {
      return;
    }

    showGraphQLLocalSchemaDumpMessage();
  });
};

if (require.main === module) {
  runEslint();
}

module.exports = {
  runEslint,
};
