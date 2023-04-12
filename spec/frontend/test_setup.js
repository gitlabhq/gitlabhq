/* Setup for unit test environment */
// eslint-disable-next-line no-restricted-syntax
import { setImmediate } from 'timers';
import Dexie from 'dexie';
import { IDBKeyRange, IDBFactory } from 'fake-indexeddb';
import 'helpers/shared_test_setup';

const indexedDB = new IDBFactory();

Dexie.dependencies.indexedDB = indexedDB;
Dexie.dependencies.IDBKeyRange = IDBKeyRange;

afterEach(() =>
  // give Promises a bit more time so they fail the right test
  // eslint-disable-next-line no-restricted-syntax
  new Promise(setImmediate).then(() => {
    // wait for pending setTimeout()s
    jest.runOnlyPendingTimers();
  }),
);

afterEach(async () => {
  const dbs = await indexedDB.databases();

  await Promise.all(dbs.map((db) => indexedDB.deleteDatabase(db.name)));
});
