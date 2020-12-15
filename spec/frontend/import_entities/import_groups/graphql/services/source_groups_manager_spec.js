import { defaultDataIdFromObject } from 'apollo-cache-inmemory';
import { SourceGroupsManager } from '~/import_entities/import_groups/graphql/services/source_groups_manager';
import ImportSourceGroupFragment from '~/import_entities/import_groups/graphql/fragments/bulk_import_source_group_item.fragment.graphql';
import { clientTypenames } from '~/import_entities/import_groups/graphql/client_factory';

describe('SourceGroupsManager', () => {
  let manager;
  let client;

  const getFakeGroup = () => ({
    __typename: clientTypenames.BulkImportSourceGroup,
    id: 5,
  });

  beforeEach(() => {
    client = {
      readFragment: jest.fn(),
      writeFragment: jest.fn(),
    };

    manager = new SourceGroupsManager({ client });
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
