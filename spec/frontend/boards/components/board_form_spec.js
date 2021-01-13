import { shallowMount } from '@vue/test-utils';

import { TEST_HOST } from 'jest/helpers/test_constants';
import { GlModal } from '@gitlab/ui';
import waitForPromises from 'helpers/wait_for_promises';

import { deprecatedCreateFlash as createFlash } from '~/flash';
import { visitUrl } from '~/lib/utils/url_utility';
import boardsStore from '~/boards/stores/boards_store';
import BoardForm from '~/boards/components/board_form.vue';
import updateBoardMutation from '~/boards/graphql/board_update.mutation.graphql';
import createBoardMutation from '~/boards/graphql/board_create.mutation.graphql';
import destroyBoardMutation from '~/boards/graphql/board_destroy.mutation.graphql';

jest.mock('~/lib/utils/url_utility', () => ({
  visitUrl: jest.fn().mockName('visitUrlMock'),
  stripFinalUrlSegment: jest.requireActual('~/lib/utils/url_utility').stripFinalUrlSegment,
}));
jest.mock('~/flash');

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

describe('BoardForm', () => {
  let wrapper;
  let mutate;

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
        rootPath: 'root',
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
    mutate = null;
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
      const fillForm = () => {
        findInput().value = 'Test name';
        findInput().trigger('input');
        findInput().trigger('keyup.enter', { metaKey: true });
      };

      beforeEach(() => {
        mutate = jest.fn().mockResolvedValue({
          data: {
            createBoard: { board: { id: 'gid://gitlab/Board/123', webPath: 'test-path' } },
          },
        });
      });

      it('does not call API if board name is empty', async () => {
        createComponent({ canAdminBoard: true });
        findInput().trigger('keyup.enter', { metaKey: true });

        await waitForPromises();

        expect(mutate).not.toHaveBeenCalled();
      });

      it('calls a correct GraphQL mutation and redirects to correct page from existing board', async () => {
        createComponent({ canAdminBoard: true });
        fillForm();

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
        expect(visitUrl).toHaveBeenCalledWith('test-path');
      });

      it('shows an error flash if GraphQL mutation fails', async () => {
        mutate = jest.fn().mockRejectedValue('Houston, we have a problem');
        createComponent({ canAdminBoard: true });
        fillForm();

        await waitForPromises();

        expect(mutate).toHaveBeenCalled();

        await waitForPromises();
        expect(visitUrl).not.toHaveBeenCalled();
        expect(createFlash).toHaveBeenCalled();
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

    it('calls GraphQL mutation with correct parameters when issues are not grouped', async () => {
      mutate = jest.fn().mockResolvedValue({
        data: {
          updateBoard: { board: { id: 'gid://gitlab/Board/321', webPath: 'test-path' } },
        },
      });
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
      expect(visitUrl).toHaveBeenCalledWith('test-path');
    });

    it('calls GraphQL mutation with correct parameters when issues are grouped by epic', async () => {
      mutate = jest.fn().mockResolvedValue({
        data: {
          updateBoard: { board: { id: 'gid://gitlab/Board/321', webPath: 'test-path' } },
        },
      });
      window.location = new URL('https://test/boards/1?group_by=epic');
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
      expect(visitUrl).toHaveBeenCalledWith('test-path?group_by=epic');
    });

    it('shows an error flash if GraphQL mutation fails', async () => {
      mutate = jest.fn().mockRejectedValue('Houston, we have a problem');
      createComponent({ canAdminBoard: true });
      findInput().trigger('keyup.enter', { metaKey: true });

      await waitForPromises();

      expect(mutate).toHaveBeenCalled();

      await waitForPromises();
      expect(visitUrl).not.toHaveBeenCalled();
      expect(createFlash).toHaveBeenCalled();
    });
  });

  describe('when deleting a board', () => {
    beforeEach(() => {
      boardsStore.state.currentPage = 'delete';
    });

    it('passes correct primary action text and variant', () => {
      createComponent({ canAdminBoard: true });
      expect(findModalActionPrimary().text).toBe('Delete');
      expect(findModalActionPrimary().attributes[0].variant).toBe('danger');
    });

    it('renders delete confirmation message', () => {
      createComponent({ canAdminBoard: true });
      expect(findDeleteConfirmation().exists()).toBe(true);
    });

    it('calls a correct GraphQL mutation and redirects to correct page after deleting board', async () => {
      mutate = jest.fn().mockResolvedValue({});
      createComponent({ canAdminBoard: true });
      findModal().vm.$emit('primary');

      await waitForPromises();

      expect(mutate).toHaveBeenCalledWith({
        mutation: destroyBoardMutation,
        variables: {
          id: 'gid://gitlab/Board/1',
        },
      });

      await waitForPromises();
      expect(visitUrl).toHaveBeenCalledWith('root');
    });

    it('shows an error flash if GraphQL mutation fails', async () => {
      mutate = jest.fn().mockRejectedValue('Houston, we have a problem');
      createComponent({ canAdminBoard: true });
      findModal().vm.$emit('primary');

      await waitForPromises();

      expect(mutate).toHaveBeenCalled();

      await waitForPromises();
      expect(visitUrl).not.toHaveBeenCalled();
      expect(createFlash).toHaveBeenCalled();
    });
  });
});
