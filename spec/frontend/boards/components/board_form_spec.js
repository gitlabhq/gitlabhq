import { shallowMount } from '@vue/test-utils';

import { TEST_HOST } from 'jest/helpers/test_constants';
import { GlModal } from '@gitlab/ui';
import waitForPromises from 'helpers/wait_for_promises';

import { visitUrl } from '~/lib/utils/url_utility';
import boardsStore from '~/boards/stores/boards_store';
import BoardForm from '~/boards/components/board_form.vue';
import updateBoardMutation from '~/boards/graphql/board_update.mutation.graphql';
import createBoardMutation from '~/boards/graphql/board_create.mutation.graphql';

jest.mock('~/lib/utils/url_utility', () => ({
  visitUrl: jest.fn().mockName('visitUrlMock'),
  stripFinalUrlSegment: jest.requireActual('~/lib/utils/url_utility').stripFinalUrlSegment,
}));

const currentBoard = {
  id: 1,
  name: 'test',
  labels: [],
  milestone_id: undefined,
  assignee: {},
  assignee_id: undefined,
  weight: null,
  hide_backlog_list: false,
  hide_closed_list: false,
};

const defaultProps = {
  canAdminBoard: false,
  labelsPath: `${TEST_HOST}/labels/path`,
  labelsWebUrl: `${TEST_HOST}/-/labels`,
  currentBoard,
};

const endpoints = {
  boardsEndpoint: 'test-endpoint',
};

const mutate = jest.fn().mockResolvedValue({
  data: {
    createBoard: { board: { id: 'gid://gitlab/Board/123' } },
    updateBoard: { board: { id: 'gid://gitlab/Board/321' } },
  },
});

describe('BoardForm', () => {
  let wrapper;

  const findModal = () => wrapper.find(GlModal);
  const findModalActionPrimary = () => findModal().props('actionPrimary');
  const findForm = () => wrapper.find('[data-testid="board-form"]');
  const findFormWrapper = () => wrapper.find('[data-testid="board-form-wrapper"]');
  const findDeleteConfirmation = () => wrapper.find('[data-testid="delete-confirmation-message"]');
  const findInput = () => wrapper.find('#board-new-name');

  const createComponent = (props, data) => {
    wrapper = shallowMount(BoardForm, {
      propsData: { ...defaultProps, ...props },
      data() {
        return {
          ...data,
        };
      },
      provide: {
        endpoints,
      },
      mocks: {
        $apollo: {
          mutate,
        },
      },
      attachTo: document.body,
    });
  };

  beforeEach(() => {
    delete window.location;
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    boardsStore.state.currentPage = null;
  });

  describe('when user can not admin the board', () => {
    beforeEach(() => {
      boardsStore.state.currentPage = 'new';
      createComponent();
    });

    it('hides modal footer when user is not a board admin', () => {
      expect(findModal().attributes('hide-footer')).toBeDefined();
    });

    it('displays board scope title', () => {
      expect(findModal().attributes('title')).toBe('Board scope');
    });

    it('does not display a form', () => {
      expect(findForm().exists()).toBe(false);
    });
  });

  describe('when user can admin the board', () => {
    beforeEach(() => {
      boardsStore.state.currentPage = 'new';
      createComponent({ canAdminBoard: true });
    });

    it('shows modal footer when user is a board admin', () => {
      expect(findModal().attributes('hide-footer')).toBeUndefined();
    });

    it('displays a form', () => {
      expect(findForm().exists()).toBe(true);
    });

    it('focuses an input field', async () => {
      expect(document.activeElement).toBe(wrapper.vm.$refs.name);
    });
  });

  describe('when creating a new board', () => {
    beforeEach(() => {
      boardsStore.state.currentPage = 'new';
    });

    describe('on non-scoped-board', () => {
      beforeEach(() => {
        createComponent({ canAdminBoard: true });
      });

      it('clears the form', () => {
        expect(findInput().element.value).toBe('');
      });

      it('shows a correct title about creating a board', () => {
        expect(findModal().attributes('title')).toBe('Create new board');
      });

      it('passes correct primary action text and variant', () => {
        expect(findModalActionPrimary().text).toBe('Create board');
        expect(findModalActionPrimary().attributes[0].variant).toBe('success');
      });

      it('does not render delete confirmation message', () => {
        expect(findDeleteConfirmation().exists()).toBe(false);
      });

      it('renders form wrapper', () => {
        expect(findFormWrapper().exists()).toBe(true);
      });
    });

    describe('when submitting a create event', () => {
      it('does not call API if board name is empty', async () => {
        createComponent({ canAdminBoard: true });
        findInput().trigger('keyup.enter', { metaKey: true });

        await waitForPromises();

        expect(mutate).not.toHaveBeenCalled();
      });

      it('calls a correct GraphQL mutation and redirects to correct page from existing board', async () => {
        window.location = new URL('https://test/boards/1');
        createComponent({ canAdminBoard: true });

        findInput().value = 'Test name';
        findInput().trigger('input');
        findInput().trigger('keyup.enter', { metaKey: true });

        await waitForPromises();

        expect(mutate).toHaveBeenCalledWith({
          mutation: createBoardMutation,
          variables: {
            input: expect.objectContaining({
              name: 'test',
            }),
          },
        });

        await waitForPromises();
        expect(visitUrl).toHaveBeenCalledWith('123');
      });

      it('calls a correct GraphQL mutation and redirects to correct page from boards list', async () => {
        window.location = new URL('https://test/boards');
        createComponent({ canAdminBoard: true });

        findInput().value = 'Test name';
        findInput().trigger('input');
        findInput().trigger('keyup.enter', { metaKey: true });

        await waitForPromises();

        expect(mutate).toHaveBeenCalledWith({
          mutation: createBoardMutation,
          variables: {
            input: expect.objectContaining({
              name: 'test',
            }),
          },
        });

        await waitForPromises();
        expect(visitUrl).toHaveBeenCalledWith('boards/123');
      });
    });
  });

  describe('when editing a board', () => {
    beforeEach(() => {
      boardsStore.state.currentPage = 'edit';
    });

    describe('on non-scoped-board', () => {
      beforeEach(() => {
        createComponent({ canAdminBoard: true });
      });

      it('clears the form', () => {
        expect(findInput().element.value).toEqual(currentBoard.name);
      });

      it('shows a correct title about creating a board', () => {
        expect(findModal().attributes('title')).toBe('Edit board');
      });

      it('passes correct primary action text and variant', () => {
        expect(findModalActionPrimary().text).toBe('Save changes');
        expect(findModalActionPrimary().attributes[0].variant).toBe('info');
      });

      it('does not render delete confirmation message', () => {
        expect(findDeleteConfirmation().exists()).toBe(false);
      });

      it('renders form wrapper', () => {
        expect(findFormWrapper().exists()).toBe(true);
      });
    });

    describe('when submitting an update event', () => {
      it('calls REST and GraphQL API with correct parameters', async () => {
        window.location = new URL('https://test/boards/1');
        createComponent({ canAdminBoard: true });

        findInput().trigger('keyup.enter', { metaKey: true });

        await waitForPromises();

        expect(mutate).toHaveBeenCalledWith({
          mutation: updateBoardMutation,
          variables: {
            input: expect.objectContaining({
              id: `gid://gitlab/Board/${currentBoard.id}`,
            }),
          },
        });

        await waitForPromises();
        expect(visitUrl).toHaveBeenCalledWith('321');
      });
    });
  });
});
