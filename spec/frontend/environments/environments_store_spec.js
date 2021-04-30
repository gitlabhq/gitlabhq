import Store from '~/environments/stores/environments_store';
import { environmentsList, serverData, deployBoardMockData } from './mock_data';

describe('Store', () => {
  let store;

  beforeEach(() => {
    store = new Store();
  });

  it('should start with a blank state', () => {
    expect(store.state.environments.length).toEqual(0);
    expect(store.state.stoppedCounter).toEqual(0);
    expect(store.state.availableCounter).toEqual(0);
    expect(store.state.paginationInformation).toEqual({});
  });

  it('should store environments', () => {
    store.storeEnvironments(serverData);

    expect(store.state.environments.length).toEqual(serverData.length);
    expect(store.state.environments[0]).toEqual(environmentsList[0]);
  });

  it('should store available count', () => {
    store.storeAvailableCount(2);

    expect(store.state.availableCounter).toEqual(2);
  });

  it('should store stopped count', () => {
    store.storeStoppedCount(2);

    expect(store.state.stoppedCounter).toEqual(2);
  });

  it('should add folder keys when environment is a folder', () => {
    const environment = {
      name: 'bar',
      size: 3,
      id: 2,
    };

    store.storeEnvironments([environment]);

    expect(store.state.environments[0].isFolder).toEqual(true);
    expect(store.state.environments[0].folderName).toEqual('bar');
  });

  it('should extract content of `latest` key when provided', () => {
    const environment = {
      name: 'bar',
      size: 3,
      id: 2,
      latest: {
        last_deployment: {},
        isStoppable: true,
      },
    };

    store.storeEnvironments([environment]);

    expect(store.state.environments[0].last_deployment).toEqual({});
    expect(store.state.environments[0].isStoppable).toEqual(true);
  });

  it('should store latest.name when the environment is not a folder', () => {
    store.storeEnvironments(serverData);

    expect(store.state.environments[0].name).toEqual(serverData[0].latest.name);
  });

  it('should store root level name when environment is a folder', () => {
    store.storeEnvironments(serverData);

    expect(store.state.environments[1].folderName).toEqual(serverData[1].name);
  });

  describe('toggleFolder', () => {
    it('should toggle folder', () => {
      store.storeEnvironments(serverData);

      store.toggleFolder(store.state.environments[1]);

      expect(store.state.environments[1].isOpen).toEqual(true);

      store.toggleFolder(store.state.environments[1]);

      expect(store.state.environments[1].isOpen).toEqual(false);
    });

    it('should keep folder open when environments are updated', () => {
      store.storeEnvironments(serverData);

      store.toggleFolder(store.state.environments[1]);

      expect(store.state.environments[1].isOpen).toEqual(true);

      store.storeEnvironments(serverData);

      expect(store.state.environments[1].isOpen).toEqual(true);
    });
  });

  describe('setfolderContent', () => {
    it('should store folder content', () => {
      store.storeEnvironments(serverData);

      store.setfolderContent(store.state.environments[1], serverData);

      expect(store.state.environments[1].children.length).toEqual(serverData.length);
      expect(store.state.environments[1].children[0].isChildren).toEqual(true);
    });

    it('should keep folder content when environments are updated', () => {
      store.storeEnvironments(serverData);

      store.setfolderContent(store.state.environments[1], serverData);

      expect(store.state.environments[1].children.length).toEqual(serverData.length);
      // poll
      store.storeEnvironments(serverData);

      expect(store.state.environments[1].children.length).toEqual(serverData.length);
    });

    it('should parse deploy board data for children', () => {
      store.storeEnvironments(serverData);

      store.setfolderContent(store.state.environments[1], [
        {
          name: 'foo',
          size: 1,
          latest: {
            id: 1,
            rollout_status: deployBoardMockData,
          },
        },
      ]);
      const result = store.state.environments[1].children[0];
      expect(result).toMatchObject({
        deployBoardData: deployBoardMockData,
        hasDeployBoard: true,
        isDeployBoardVisible: true,
        isLoadingDeployBoard: false,
        isEmptyDeployBoard: false,
      });
    });
  });

  describe('store pagination', () => {
    it('should store normalized and integer pagination information', () => {
      const pagination = {
        'X-nExt-pAge': '2',
        'X-page': '1',
        'X-Per-Page': '1',
        'X-Prev-Page': '2',
        'X-TOTAL': '37',
        'X-Total-Pages': '2',
      };

      const expectedResult = {
        perPage: 1,
        page: 1,
        total: 37,
        totalPages: 2,
        nextPage: 2,
        previousPage: 2,
      };

      store.setPagination(pagination);

      expect(store.state.paginationInformation).toEqual(expectedResult);
    });
  });

  describe('getOpenFolders', () => {
    it('should return open folder', () => {
      store.storeEnvironments(serverData);

      store.toggleFolder(store.state.environments[1]);

      expect(store.getOpenFolders()[0]).toEqual(store.state.environments[1]);
    });
  });

  it('should store a non folder environment with deploy board if rollout_status key is provided', () => {
    const environment = {
      name: 'foo',
      size: 1,
      latest: {
        id: 1,
        rollout_status: deployBoardMockData,
      },
    };

    store.storeEnvironments([environment]);

    expect(store.state.environments[0].hasDeployBoard).toEqual(true);
    expect(store.state.environments[0].isDeployBoardVisible).toEqual(true);
    expect(store.state.environments[0].deployBoardData).toEqual(deployBoardMockData);
  });

  describe('deploy boards', () => {
    beforeEach(() => {
      const environment = {
        name: 'foo',
        size: 1,
        latest: {
          id: 1,
        },
        rollout_status: deployBoardMockData,
      };

      store.storeEnvironments([environment]);
    });

    it('should toggle deploy board property for given environment id', () => {
      store.toggleDeployBoard(1);

      expect(store.state.environments[0].isDeployBoardVisible).toEqual(false);
    });

    it('should keep deploy board data when updating environments', () => {
      expect(store.state.environments[0].deployBoardData).toEqual(deployBoardMockData);

      const environment = {
        name: 'foo',
        size: 1,
        latest: {
          id: 1,
        },
        rollout_status: deployBoardMockData,
      };
      store.storeEnvironments([environment]);

      expect(store.state.environments[0].deployBoardData).toEqual(deployBoardMockData);
    });
  });
});
