/* Setup for unit test environment */
// eslint-disable-next-line no-restricted-syntax
import { setImmediate } from 'timers';
import Dexie from 'dexie';
import { IDBKeyRange, IDBFactory } from 'fake-indexeddb';
import 'helpers/shared_test_setup';
import { forgetConsoleCalls, getConsoleCalls, throwErrorFromCalls } from 'helpers/console_watcher';

const indexedDB = new IDBFactory();

Dexie.dependencies.indexedDB = indexedDB;
Dexie.dependencies.IDBKeyRange = IDBKeyRange;

process.env.PDF_JS_WORKER_PUBLIC_PATH = 'mock/path/v4/pdf.worker.js';

afterEach(() =>
  // give Promises a bit more time so they fail the right test
  // eslint-disable-next-line no-restricted-syntax
  new Promise(setImmediate).then(() => {
    // wait for pending setTimeout()s
    jest.runOnlyPendingTimers();
  }),
);

afterEach(() => {
  const consoleCalls = getConsoleCalls();
  forgetConsoleCalls();

  if (consoleCalls.length) {
    throwErrorFromCalls(consoleCalls);
  }
});

afterEach(async () => {
  const dbs = await indexedDB.databases();

  await Promise.all(dbs.map((db) => indexedDB.deleteDatabase(db.name)));
});
