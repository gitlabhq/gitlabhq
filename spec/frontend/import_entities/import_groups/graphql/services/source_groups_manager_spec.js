import {
  KEY,
  SourceGroupsManager,
} from '~/import_entities/import_groups/graphql/services/source_groups_manager';

const FAKE_SOURCE_URL = 'http://demo.host';

describe('SourceGroupsManager', () => {
  let manager;
  let storage;

  beforeEach(() => {
    storage = {
      getItem: jest.fn(),
      setItem: jest.fn(),
    };

    manager = new SourceGroupsManager({ storage, sourceUrl: FAKE_SOURCE_URL });
  });

  describe('storage management', () => {
    const IMPORT_ID = 1;
    const IMPORT_TARGET = { destination_name: 'demo', destination_namespace: 'foo' };
    const STATUS = 'FAKE_STATUS';
    const FAKE_GROUP = { id: 1, importTarget: IMPORT_TARGET, status: STATUS };

    it('loads state from storage on creation', () => {
      expect(storage.getItem).toHaveBeenCalledWith(KEY);
    });

    it('saves to storage when saveImportState is called', () => {
      manager.saveImportState(IMPORT_ID, FAKE_GROUP);
      const storedObject = JSON.parse(storage.setItem.mock.calls[0][1]);
      expect(Object.values(storedObject)[0]).toStrictEqual({
        id: FAKE_GROUP.id,
        importTarget: IMPORT_TARGET,
        status: STATUS,
      });
    });

    it('updates storage when previous state is available', () => {
      const CHANGED_STATUS = 'changed';

      manager.saveImportState(IMPORT_ID, FAKE_GROUP);

      manager.saveImportState(IMPORT_ID, { status: CHANGED_STATUS });
      const storedObject = JSON.parse(storage.setItem.mock.calls[1][1]);
      expect(Object.values(storedObject)[0]).toStrictEqual({
        id: FAKE_GROUP.id,
        importTarget: IMPORT_TARGET,
        status: CHANGED_STATUS,
      });
    });
  });
});
