#!/usr/bin/env node

const fs = require('fs/promises');
const path = require('path');
const assert = require('assert');

const ROOT_DIR = path.join(__dirname, '../../');
const GRAPHQL_SCHEMA = path.join(ROOT_DIR, 'tmp/tests/graphql/gitlab_schema.json');
const POSSIBLE_TYPES_REL = 'app/assets/javascripts/graphql_shared/possible_types.json';
const POSSIBLE_TYPES = path.join(ROOT_DIR, POSSIBLE_TYPES_REL);

function extractTypes(schema) {
  return Object.fromEntries(
    // eslint-disable-next-line no-underscore-dangle
    schema.data.__schema.types
      .filter((type) => type.possibleTypes)
      .map(({ name, possibleTypes }) => [name, possibleTypes.map((subtype) => subtype.name)]),
  );
}

async function main() {
  let schema;
  try {
    schema = JSON.parse(await fs.readFile(GRAPHQL_SCHEMA, 'utf-8'));
  } catch (e) {
    console.error(
      'Could not read the GraphQL Schema, make sure to run: bundle exec rake gitlab:graphql:schema:dump',
    );
    throw e;
  }

  const possibleTypes = extractTypes(schema);

  if (process.argv.includes('--check')) {
    const previousTypes = JSON.parse(await fs.readFile(POSSIBLE_TYPES, 'utf-8'));

    assert.deepStrictEqual(
      previousTypes,
      possibleTypes,
      `
${POSSIBLE_TYPES_REL} needs to be regenerated, please run:
    node scripts/frontend/graphql_possible_types_extraction.js --write
and commit the changes!
    `,
    );
    return;
  }

  if (process.argv.includes('--write')) {
    const stringifiedPossibleTypes = JSON.stringify(possibleTypes, null, 2);
    await fs.writeFile(POSSIBLE_TYPES, `${stringifiedPossibleTypes}\n`);
    console.log(`Successfully updated ${POSSIBLE_TYPES_REL}`);
    return;
  }

  throw new Error(`
ERROR: Please use the script correctly:
Usage: graphql_possible_types_extraction [options]

Options:
  --check  Check whether there are new Interface or Union types
  --write  Generate new possible types
  `);
}

main().catch((error) => {
  console.warn(error.message);
  console.warn(error.stack);
  process.exitCode = 1;
});
