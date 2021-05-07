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
    const FAKE_GROUP = { id: 1, import_target: IMPORT_TARGET, status: STATUS };

    it('loads state from storage on creation', () => {
      expect(storage.getItem).toHaveBeenCalledWith(KEY);
    });

    it('saves to storage when createImportState is called', () => {
      const FAKE_STATUS = 'fake;';
      manager.createImportState(IMPORT_ID, { status: FAKE_STATUS, groups: [FAKE_GROUP] });
      const storedObject = JSON.parse(storage.setItem.mock.calls[0][1]);
      expect(Object.values(storedObject)[0]).toStrictEqual({
        status: FAKE_STATUS,
        groups: [
          {
            id: FAKE_GROUP.id,
            importTarget: IMPORT_TARGET,
          },
        ],
      });
    });

    it('updates storage when previous state is available', () => {
      const CHANGED_STATUS = 'changed';

      manager.createImportState(IMPORT_ID, { status: STATUS, groups: [FAKE_GROUP] });

      manager.updateImportProgress(IMPORT_ID, CHANGED_STATUS);
      const storedObject = JSON.parse(storage.setItem.mock.calls[1][1]);
      expect(Object.values(storedObject)[0]).toStrictEqual({
        status: CHANGED_STATUS,
        groups: [
          {
            id: FAKE_GROUP.id,
            importTarget: IMPORT_TARGET,
          },
        ],
      });
    });
  });
});
