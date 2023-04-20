import { IndexedDBPersistentStorage } from '~/lib/apollo/indexed_db_persistent_storage';
import { db } from '~/lib/apollo/local_db';
import CACHE_WITH_PERSIST_DIRECTIVE_AND_FIELDS from './mock_data/cache_with_persist_directive_and_field.json';

describe('IndexedDBPersistentStorage', () => {
  let subject;

  const seedData = async (cacheKey, data = CACHE_WITH_PERSIST_DIRECTIVE_AND_FIELDS) => {
    const { ROOT_QUERY, ...rest } = data;

    await db.table('queries').put(ROOT_QUERY, cacheKey);

    const asyncPuts = Object.entries(rest).map(async ([key, value]) => {
      const {
        groups: { type, gid },
      } = /^(?<type>.+?):(?<gid>.+)$/.exec(key);
      const tableName = type.toLowerCase();

      if (tableName !== 'projectmember' && tableName !== 'groupmember') {
        await db.table(tableName).put(value, gid);
      }
    });

    await Promise.all(asyncPuts);
  };

  beforeEach(async () => {
    subject = await IndexedDBPersistentStorage.create();
  });

  afterEach(() => {
    db.close();
  });

  it('returns empty response if there is nothing stored in the DB', async () => {
    const result = await subject.getItem('some-query');

    expect(result).toEqual({});
  });

  it('returns stored cache if cache was persisted in IndexedDB', async () => {
    await seedData('issues_list', CACHE_WITH_PERSIST_DIRECTIVE_AND_FIELDS);

    const result = await subject.getItem('issues_list');
    expect(result).toEqual(CACHE_WITH_PERSIST_DIRECTIVE_AND_FIELDS);
  });

  it('puts the results in database on `setItem` call', async () => {
    await subject.setItem(
      'issues_list',
      JSON.stringify({
        ROOT_QUERY: 'ROOT_QUERY_KEY',
        'Project:gid://gitlab/Project/6': {
          __typename: 'Project',
          id: 'gid://gitlab/Project/6',
        },
      }),
    );

    await expect(db.table('queries').get('issues_list')).resolves.toEqual('ROOT_QUERY_KEY');
    await expect(db.table('project').get('gid://gitlab/Project/6')).resolves.toEqual({
      __typename: 'Project',
      id: 'gid://gitlab/Project/6',
    });
  });

  it('does not put results into non-existent table', async () => {
    const queryId = 'issues_list';

    await subject.setItem(
      queryId,
      JSON.stringify({
        ROOT_QUERY: 'ROOT_QUERY_KEY',
        'DNE:gid://gitlab/DNE/1': {},
      }),
    );

    expect(db.tables.map((x) => x.name)).not.toContain('dne');
  });

  it('when removeItem is called, clears all data', async () => {
    await seedData('issues_list', CACHE_WITH_PERSIST_DIRECTIVE_AND_FIELDS);

    await subject.removeItem();

    const actual = await Promise.all(db.tables.map((x) => x.toArray()));

    expect(actual).toEqual(db.tables.map(() => []));
  });
});
