/* Setup for unit test environment */
import Dexie from 'dexie';
import { IDBKeyRange, IDBFactory } from 'fake-indexeddb';
import 'helpers/shared_test_setup';
import { forgetConsoleCalls, getConsoleCalls, throwErrorFromCalls } from 'helpers/console_watcher';

const indexedDB = new IDBFactory();

Dexie.dependencies.indexedDB = indexedDB;
Dexie.dependencies.IDBKeyRange = IDBKeyRange;

process.env.PDF_JS_WORKER_PUBLIC_PATH = 'mock/path/v4/pdf.worker.js';
process.env.PDF_JS_CMAPS_PUBLIC_PATH = '/assets/webpack/pdfjs/v4/cmaps/';

afterEach(() => {
  jest.clearAllTimers();
});

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
