import { defaultDataIdFromObject } from 'apollo-cache-inmemory';
import { clientTypenames } from '~/import_entities/import_groups/graphql/client_factory';
import ImportSourceGroupFragment from '~/import_entities/import_groups/graphql/fragments/bulk_import_source_group_item.fragment.graphql';
import {
  KEY,
  SourceGroupsManager,
} from '~/import_entities/import_groups/graphql/services/source_groups_manager';

const FAKE_SOURCE_URL = 'http://demo.host';

describe('SourceGroupsManager', () => {
  let manager;
  let client;
  let storage;

  const getFakeGroup = () => ({
    __typename: clientTypenames.BulkImportSourceGroup,
    id: 5,
  });

  beforeEach(() => {
    client = {
      readFragment: jest.fn(),
      writeFragment: jest.fn(),
    };
    storage = {
      getItem: jest.fn(),
      setItem: jest.fn(),
    };

    manager = new SourceGroupsManager({ client, storage, sourceUrl: FAKE_SOURCE_URL });
  });

  describe('storage management', () => {
    const IMPORT_ID = 1;
    const IMPORT_TARGET = { destination_name: 'demo', destination_namespace: 'foo' };
    const STATUS = 'FAKE_STATUS';
    const FAKE_GROUP = { id: 1, import_target: IMPORT_TARGET, status: STATUS };

    it('loads state from storage on creation', () => {
      expect(storage.getItem).toHaveBeenCalledWith(KEY);
    });

    it('saves to storage when import is starting', () => {
      manager.startImport({
        importId: IMPORT_ID,
        group: FAKE_GROUP,
      });
      const storedObject = JSON.parse(storage.setItem.mock.calls[0][1]);
      expect(Object.values(storedObject)[0]).toStrictEqual({
        id: FAKE_GROUP.id,
        importTarget: IMPORT_TARGET,
        status: STATUS,
      });
    });

    it('saves to storage when import status is updated', () => {
      const CHANGED_STATUS = 'changed';

      manager.startImport({
        importId: IMPORT_ID,
        group: FAKE_GROUP,
      });

      manager.setImportStatusByImportId(IMPORT_ID, CHANGED_STATUS);
      const storedObject = JSON.parse(storage.setItem.mock.calls[1][1]);
      expect(Object.values(storedObject)[0]).toStrictEqual({
        id: FAKE_GROUP.id,
        importTarget: IMPORT_TARGET,
        status: CHANGED_STATUS,
      });
    });
  });

  it('finds item by group id', () => {
    const ID = 5;

    const FAKE_GROUP = getFakeGroup();
    client.readFragment.mockReturnValue(FAKE_GROUP);
    const group = manager.findById(ID);
    expect(group).toBe(FAKE_GROUP);
    expect(client.readFragment).toHaveBeenCalledWith({
      fragment: ImportSourceGroupFragment,
      id: defaultDataIdFromObject(getFakeGroup()),
    });
  });

  it('updates group with provided function', () => {
    const UPDATED_GROUP = {};
    const fn = jest.fn().mockReturnValue(UPDATED_GROUP);
    manager.update(getFakeGroup(), fn);

    expect(client.writeFragment).toHaveBeenCalledWith({
      fragment: ImportSourceGroupFragment,
      id: defaultDataIdFromObject(getFakeGroup()),
      data: UPDATED_GROUP,
    });
  });

  it('updates group by id with provided function', () => {
    const UPDATED_GROUP = {};
    const fn = jest.fn().mockReturnValue(UPDATED_GROUP);
    client.readFragment.mockReturnValue(getFakeGroup());
    manager.updateById(getFakeGroup().id, fn);

    expect(client.readFragment).toHaveBeenCalledWith({
      fragment: ImportSourceGroupFragment,
      id: defaultDataIdFromObject(getFakeGroup()),
    });

    expect(client.writeFragment).toHaveBeenCalledWith({
      fragment: ImportSourceGroupFragment,
      id: defaultDataIdFromObject(getFakeGroup()),
      data: UPDATED_GROUP,
    });
  });

  it('sets import status when group is provided', () => {
    client.readFragment.mockReturnValue(getFakeGroup());

    const NEW_STATUS = 'NEW_STATUS';
    manager.setImportStatus(getFakeGroup(), NEW_STATUS);

    expect(client.writeFragment).toHaveBeenCalledWith({
      fragment: ImportSourceGroupFragment,
      id: defaultDataIdFromObject(getFakeGroup()),
      data: {
        ...getFakeGroup(),
        status: NEW_STATUS,
      },
    });
  });
});
