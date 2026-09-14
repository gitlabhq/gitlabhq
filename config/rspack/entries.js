const { baseEntryPoints } = require('../helpers/entry_points');
const { loadVue3Migrations } = require('../helpers/vue3_migration_loader');
const { generateEntries, applyVue3Migrations } = require('../webpack.helpers');

const migrations = loadVue3Migrations();
const { entries: pageEntries, entriesState } = generateEntries(baseEntryPoints.default, {
  migrations,
});

const entries = { ...applyVue3Migrations(baseEntryPoints, { migrations }), ...pageEntries };
const { autoEntriesCount } = entriesState;

module.exports = { entries, autoEntriesCount };
