/* eslint-disable no-underscore-dangle */
/* eslint-disable class-methods-use-this */
import { db } from './local_db';

/**
 * IndexedDB implementation of apollo-cache-persist [PersistentStorage][1]
 *
 * [1]: https://github.com/apollographql/apollo-cache-persist/blob/d536c741d1f2828a0ef9abda343a9186dd8dbff2/src/types/index.ts#L15
 */
export class IndexedDBPersistentStorage {
  static async create() {
    await db.open();

    return new IndexedDBPersistentStorage();
  }

  async getItem(queryId) {
    const resultObj = {};
    const selectedQuery = await db.table('queries').get(queryId);
    const tableNames = new Set(db.tables.map((table) => table.name));

    if (selectedQuery) {
      resultObj.ROOT_QUERY = selectedQuery;

      const lookupTable = [];

      const parseObjectsForRef = async (selObject) => {
        const ops = Object.values(selObject).map(async (child) => {
          if (!child) {
            return;
          }

          if (child.__ref) {
            const pathId = child.__ref;
            const [refType, ...refKeyParts] = pathId.split(':');
            const refKey = refKeyParts.join(':');

            if (
              !resultObj[pathId] &&
              !lookupTable.includes(pathId) &&
              tableNames.has(refType.toLowerCase())
            ) {
              lookupTable.push(pathId);
              const selectedEntity = await db.table(refType.toLowerCase()).get(refKey);
              if (selectedEntity) {
                await parseObjectsForRef(selectedEntity);
                resultObj[pathId] = selectedEntity;
              }
            }
          } else if (typeof child === 'object') {
            await parseObjectsForRef(child);
          }
        });

        return Promise.all(ops);
      };

      await parseObjectsForRef(resultObj.ROOT_QUERY);
    }

    return resultObj;
  }

  async setItem(key, value) {
    await this.#setQueryResults(key, JSON.parse(value));
  }

  async removeItem() {
    // apollo-cache-persist only ever calls this when we're removing everything, so let's blow it all away
    // https://gitlab.com/gitlab-org/gitlab/-/merge_requests/113745#note_1329175993

    await Promise.all(
      db.tables.map((table) => {
        return table.clear();
      }),
    );
  }

  async #setQueryResults(queryId, results) {
    await Promise.all(
      Object.keys(results).map((id) => {
        const objectType = id.split(':')[0];
        if (objectType === 'ROOT_QUERY') {
          return db.table('queries').put(results[id], queryId);
        }
        const key = objectType.toLowerCase();
        const tableExists = db.tables.some((table) => table.name === key);
        if (tableExists) {
          return db.table(key).put(results[id], id);
        }
        return new Promise((resolve) => {
          resolve();
        });
      }),
    );
  }
}
