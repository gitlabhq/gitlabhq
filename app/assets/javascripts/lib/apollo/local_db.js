/* eslint-disable @gitlab/require-i18n-strings */
import Dexie from 'dexie';

export const db = new Dexie('GLLocalCache');
db.version(1).stores({
  pages: 'url, timestamp',
  queries: '',
  project: 'id',
  group: 'id',
  usercore: 'id',
  issue: 'id, state, title',
  label: 'id, title',
  milestone: 'id',
});
