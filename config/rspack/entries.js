const { baseEntryPoints } = require('../helpers/entry_points');
const { generateEntries } = require('../webpack.helpers');

const { entries: pageEntries, entriesState } = generateEntries(baseEntryPoints.default);

const entries = { ...baseEntryPoints, ...pageEntries };
const { autoEntriesCount } = entriesState;

module.exports = { entries, autoEntriesCount };
