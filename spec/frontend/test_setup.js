/* Setup for unit test environment */
import Dexie from 'dexie';
import { IDBKeyRange, IDBFactory } from 'fake-indexeddb';
import 'helpers/shared_test_setup';

const indexedDB = new IDBFactory();

Dexie.dependencies.indexedDB = indexedDB;
Dexie.dependencies.IDBKeyRange = IDBKeyRange;

afterEach(async () => {
  const dbs = await indexedDB.databases();

  await Promise.all(dbs.map((db) => indexedDB.deleteDatabase(db.name)));
});
