import { GlCollapsibleListbox } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BoardAddNewColumn from '~/boards/components/board_add_new_column.vue';
import BoardAddNewColumnForm from '~/boards/components/board_add_new_column_form.vue';
import createBoardListMutation from 'ee_else_ce/boards/graphql/board_list_create.mutation.graphql';
import boardLabelsQuery from '~/boards/graphql/board_labels.query.graphql';
import * as cacheUpdates from '~/boards/graphql/cache_updates';
import {
  mockLabelList,
  createBoardListResponse,
  labelsQueryResponse,
  boardListsQueryResponse,
} from '../mock_data';

Vue.use(VueApollo);

describe('BoardAddNewColumn', () => {
  let wrapper;
  let mockApollo;

  const createBoardListQueryHandler = jest.fn().mockResolvedValue(createBoardListResponse);
  const labelsQueryHandler = jest.fn().mockResolvedValue(labelsQueryResponse);
  const errorMessage = 'Failed to create list';
  const createBoardListQueryHandlerFailure = jest.fn().mockRejectedValue(new Error(errorMessage));
  const errorMessageLabels = 'Failed to fetch labels';
  const labelsQueryHandlerFailure = jest.fn().mockRejectedValue(new Error(errorMessageLabels));

  const findDropdown = () => wrapper.findComponent(GlCollapsibleListbox);
  const findAddNewColumnForm = () => wrapper.findComponent(BoardAddNewColumnForm);
  const selectLabel = (id) => {
    findDropdown().vm.$emit('select', id);
  };

  const mountComponent = ({
    selectedId,
    provide = {},
    lists = {},
    labelsHandler = labelsQueryHandler,
    createHandler = createBoardListQueryHandler,
  } = {}) => {
    mockApollo = createMockApollo([
      [boardLabelsQuery, labelsHandler],
      [createBoardListMutation, createHandler],
    ]);

    wrapper = shallowMountExtended(BoardAddNewColumn, {
      apolloProvider: mockApollo,
      propsData: {
        listQueryVariables: {
          isGroup: false,
          isProject: true,
          fullPath: 'gitlab-org/gitlab',
          boardId: 'gid://gitlab/Board/1',
          filters: {},
        },
        boardId: 'gid://gitlab/Board/1',
        lists,
      },
      data() {
        return {
          selectedId,
        };
      },
      provide: {
        scopedLabelsAvailable: true,
        isEpicBoard: false,
        issuableType: 'issue',
        fullPath: 'gitlab-org/gitlab',
        boardType: 'project',
        ...provide,
      },
      stubs: {
        GlCollapsibleListbox,
      },
    });

    // trigger change event
    if (selectedId) {
      selectLabel(selectedId);
    }

    // Necessary for cache update
    mockApollo.clients.defaultClient.cache.readQuery = jest
      .fn()
      .mockReturnValue(boardListsQueryResponse.data);
    mockApollo.clients.defaultClient.cache.writeQuery = jest.fn();
  };

  beforeEach(() => {
    cacheUpdates.setError = jest.fn();
  });

  describe('when list is new', () => {
    beforeEach(() => {
      mountComponent({ selectedId: mockLabelList.label.id });
    });

    it('fetches labels and adds list', async () => {
      findDropdown().vm.$emit('show');

      await nextTick();
      expect(labelsQueryHandler).toHaveBeenCalled();

      selectLabel(mockLabelList.label.id);

      findAddNewColumnForm().vm.$emit('add-list');

      await nextTick();

      expect(wrapper.emitted('highlight-list')).toBeUndefined();
      expect(createBoardListQueryHandler).toHaveBeenCalledWith({
        labelId: mockLabelList.label.id,
        position: null,
        boardId: 'gid://gitlab/Board/1',
      });
    });
  });

  describe('when list already exists in board', () => {
    beforeEach(() => {
      mountComponent({
        lists: {
          [mockLabelList.id]: mockLabelList,
        },
        selectedId: mockLabelList.label.id,
      });
    });

    it('highlights existing list if trying to re-add', async () => {
      findDropdown().vm.$emit('show');

      await nextTick();
      expect(labelsQueryHandler).toHaveBeenCalled();

      selectLabel(mockLabelList.label.id);

      findAddNewColumnForm().vm.$emit('add-list');

      await waitForPromises();

      expect(wrapper.emitted('highlight-list')).toEqual([[mockLabelList.id]]);
      expect(createBoardListQueryHandler).not.toHaveBeenCalledWith();
    });
  });

  describe('when fetch labels query fails', () => {
    beforeEach(() => {
      mountComponent({
        labelsHandler: labelsQueryHandlerFailure,
      });
    });

    it('sets error', async () => {
      findDropdown().vm.$emit('show');

      await waitForPromises();
      expect(cacheUpdates.setError).toHaveBeenCalled();
    });
  });

  describe('when create list mutation fails', () => {
    beforeEach(() => {
      mountComponent({
        selectedId: mockLabelList.label.id,
        createHandler: createBoardListQueryHandlerFailure,
      });
    });

    it('sets error', async () => {
      findDropdown().vm.$emit('show');

      await nextTick();
      expect(labelsQueryHandler).toHaveBeenCalled();

      selectLabel(mockLabelList.label.id);

      findAddNewColumnForm().vm.$emit('add-list');

      await waitForPromises();

      expect(cacheUpdates.setError).toHaveBeenCalled();
    });
  });
});
