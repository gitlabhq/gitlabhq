const { spawn } = require('child_process');
const chalk = require('chalk');

const showCircularDependencyMessage = () => {
  console.log(`${chalk.yellow('NOTE: Circular dependency check is moved to static analysis job since it significantly slows down the CI run.')}
To see the full list of circular dependencies, run the command ${chalk.bold.cyan('DISABLE_EXCLUSIONS=1 yarn deps:check:all')}.
If you have fixed existing circular dependencies or find false positives, you can add/remove them from the
exclusions list in the 'config/dependency-cruiser.js' file.\n
${chalk.italic('If the above command fails because of memory issues, increase the memory by prepending it with the following')}
${chalk.bold.cyan('NODE_OPTIONS="--max-old-space-size=4096"')}
`);
};

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
    showCircularDependencyMessage();

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
