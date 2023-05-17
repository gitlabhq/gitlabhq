import { GlModal } from '@gitlab/ui';
import Vue from 'vue';
import Vuex from 'vuex';
import setWindowLocation from 'helpers/set_window_location_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';

import BoardForm from '~/boards/components/board_form.vue';
import { formType } from '~/boards/constants';
import createBoardMutation from '~/boards/graphql/board_create.mutation.graphql';
import destroyBoardMutation from '~/boards/graphql/board_destroy.mutation.graphql';
import updateBoardMutation from '~/boards/graphql/board_update.mutation.graphql';
import eventHub from '~/boards/eventhub';
import { visitUrl } from '~/lib/utils/url_utility';

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn().mockName('visitUrlMock'),
}));
jest.mock('~/boards/eventhub');

Vue.use(Vuex);

const currentBoard = {
  id: 'gid://gitlab/Board/1',
  name: 'test',
  labels: [],
  milestone: {},
  assignee: {},
  iteration: {},
  iterationCadence: {},
  weight: null,
  hideBacklogList: false,
  hideClosedList: false,
};

const defaultProps = {
  canAdminBoard: false,
  currentBoard,
  currentPage: '',
};

describe('BoardForm', () => {
  let wrapper;
  let mutate;

  const findModal = () => wrapper.findComponent(GlModal);
  const findModalActionPrimary = () => findModal().props('actionPrimary');
  const findForm = () => wrapper.findByTestId('board-form');
  const findFormWrapper = () => wrapper.findByTestId('board-form-wrapper');
  const findDeleteConfirmation = () => wrapper.findByTestId('delete-confirmation-message');
  const findInput = () => wrapper.find('#board-new-name');

  const setBoardMock = jest.fn();
  const setErrorMock = jest.fn();

  const store = new Vuex.Store({
    actions: {
      setBoard: setBoardMock,
      setError: setErrorMock,
    },
  });

  const createComponent = (props, provide) => {
    wrapper = shallowMountExtended(BoardForm, {
      propsData: { ...defaultProps, ...props },
      provide: {
        boardBaseUrl: 'root',
        isGroupBoard: true,
        isProjectBoard: false,
        ...provide,
      },
      mocks: {
        $apollo: {
          mutate,
        },
      },
      store,
      attachTo: document.body,
    });
  };

  afterEach(() => {
    mutate = null;
  });

  describe('when user can not admin the board', () => {
    beforeEach(() => {
      createComponent({ currentPage: formType.new });
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
      createComponent({ canAdminBoard: true, currentPage: formType.new });
    });

    it('shows modal footer when user is a board admin', () => {
      expect(findModal().attributes('hide-footer')).toBeUndefined();
    });

    it('displays a form', () => {
      expect(findForm().exists()).toBe(true);
    });

    it('focuses an input field', () => {
      expect(document.activeElement).toBe(wrapper.vm.$refs.name);
    });
  });

  describe('when creating a new board', () => {
    describe('on non-scoped-board', () => {
      beforeEach(() => {
        createComponent({ canAdminBoard: true, currentPage: formType.new });
      });

      it('clears the form', () => {
        expect(findInput().element.value).toBe('');
      });

      it('shows a correct title about creating a board', () => {
        expect(findModal().attributes('title')).toBe('Create new board');
      });

      it('passes correct primary action text and variant', () => {
        expect(findModalActionPrimary().text).toBe('Create board');
        expect(findModalActionPrimary().attributes.variant).toBe('confirm');
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
        createComponent({ canAdminBoard: true, currentPage: formType.new });
        findInput().trigger('keyup.enter', { metaKey: true });

        await waitForPromises();

        expect(mutate).not.toHaveBeenCalled();
      });

      it('calls a correct GraphQL mutation and sets board in state', async () => {
        createComponent({ canAdminBoard: true, currentPage: formType.new });
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
        expect(setBoardMock).toHaveBeenCalledTimes(1);
      });

      it('sets error in state if GraphQL mutation fails', async () => {
        mutate = jest.fn().mockRejectedValue('Houston, we have a problem');
        createComponent({ canAdminBoard: true, currentPage: formType.new });

        fillForm();

        await waitForPromises();

        expect(mutate).toHaveBeenCalled();

        await waitForPromises();
        expect(setBoardMock).not.toHaveBeenCalled();
        expect(setErrorMock).toHaveBeenCalled();
      });

      describe('when Apollo boards FF is on', () => {
        it('calls a correct GraphQL mutation and emits addBoard event when creating a board', async () => {
          createComponent(
            { canAdminBoard: true, currentPage: formType.new },
            { isApolloBoard: true },
          );
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
          expect(wrapper.emitted('addBoard')).toHaveLength(1);
        });
      });
    });
  });

  describe('when editing a board', () => {
    describe('on non-scoped-board', () => {
      beforeEach(() => {
        createComponent({ canAdminBoard: true, currentPage: formType.edit });
      });

      it('clears the form', () => {
        expect(findInput().element.value).toEqual(currentBoard.name);
      });

      it('shows a correct title about creating a board', () => {
        expect(findModal().attributes('title')).toBe('Edit board');
      });

      it('passes correct primary action text and variant', () => {
        expect(findModalActionPrimary().text).toBe('Save changes');
        expect(findModalActionPrimary().attributes.variant).toBe('confirm');
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
      setWindowLocation('https://test/boards/1');
      createComponent({ canAdminBoard: true, currentPage: formType.edit });

      findInput().trigger('keyup.enter', { metaKey: true });

      await waitForPromises();

      expect(mutate).toHaveBeenCalledWith({
        mutation: updateBoardMutation,
        variables: {
          input: expect.objectContaining({
            id: currentBoard.id,
          }),
        },
      });

      await waitForPromises();
      expect(setBoardMock).toHaveBeenCalledTimes(1);
      expect(global.window.location.href).not.toContain('?group_by=epic');
    });

    it('calls GraphQL mutation with correct parameters when issues are grouped by epic', async () => {
      mutate = jest.fn().mockResolvedValue({
        data: {
          updateBoard: { board: { id: 'gid://gitlab/Board/321', webPath: 'test-path' } },
        },
      });
      setWindowLocation('https://test/boards/1?group_by=epic');
      createComponent({ canAdminBoard: true, currentPage: formType.edit });

      findInput().trigger('keyup.enter', { metaKey: true });

      await waitForPromises();

      expect(mutate).toHaveBeenCalledWith({
        mutation: updateBoardMutation,
        variables: {
          input: expect.objectContaining({
            id: currentBoard.id,
          }),
        },
      });

      await waitForPromises();
      expect(setBoardMock).toHaveBeenCalledTimes(1);
      expect(global.window.location.href).toContain('?group_by=epic');
    });

    it('sets error in state if GraphQL mutation fails', async () => {
      mutate = jest.fn().mockRejectedValue('Houston, we have a problem');
      createComponent({ canAdminBoard: true, currentPage: formType.edit });

      findInput().trigger('keyup.enter', { metaKey: true });

      await waitForPromises();

      expect(mutate).toHaveBeenCalled();

      await waitForPromises();
      expect(setBoardMock).not.toHaveBeenCalled();
      expect(setErrorMock).toHaveBeenCalled();
    });

    describe('when Apollo boards FF is on', () => {
      it('calls a correct GraphQL mutation and emits updateBoard event when updating a board', async () => {
        mutate = jest.fn().mockResolvedValue({
          data: {
            updateBoard: { board: { id: 'gid://gitlab/Board/321', webPath: 'test-path' } },
          },
        });
        setWindowLocation('https://test/boards/1');

        createComponent(
          { canAdminBoard: true, currentPage: formType.edit },
          { isApolloBoard: true },
        );
        findInput().trigger('keyup.enter', { metaKey: true });

        await waitForPromises();

        expect(mutate).toHaveBeenCalledWith({
          mutation: updateBoardMutation,
          variables: {
            input: expect.objectContaining({
              id: currentBoard.id,
            }),
          },
        });

        await waitForPromises();
        expect(eventHub.$emit).toHaveBeenCalledTimes(1);
        expect(eventHub.$emit).toHaveBeenCalledWith('updateBoard', {
          id: 'gid://gitlab/Board/321',
          webPath: 'test-path',
        });
      });
    });
  });

  describe('when deleting a board', () => {
    it('passes correct primary action text and variant', () => {
      createComponent({ canAdminBoard: true, currentPage: formType.delete });
      expect(findModalActionPrimary().text).toBe('Delete');
      expect(findModalActionPrimary().attributes.variant).toBe('danger');
    });

    it('renders delete confirmation message', () => {
      createComponent({ canAdminBoard: true, currentPage: formType.delete });
      expect(findDeleteConfirmation().exists()).toBe(true);
    });

    it('calls a correct GraphQL mutation and redirects to correct page after deleting board', async () => {
      mutate = jest.fn().mockResolvedValue({});
      createComponent({ canAdminBoard: true, currentPage: formType.delete });
      findModal().vm.$emit('primary');

      await waitForPromises();

      expect(mutate).toHaveBeenCalledWith({
        mutation: destroyBoardMutation,
        variables: {
          id: currentBoard.id,
        },
      });

      await waitForPromises();
      expect(visitUrl).toHaveBeenCalledWith('root');
    });

    it('dispatches `setError` action when GraphQL mutation fails', async () => {
      mutate = jest.fn().mockRejectedValue('Houston, we have a problem');
      createComponent({ canAdminBoard: true, currentPage: formType.delete });
      jest.spyOn(wrapper.vm, 'setError').mockImplementation(() => {});

      findModal().vm.$emit('primary');

      await waitForPromises();

      expect(mutate).toHaveBeenCalled();

      await waitForPromises();
      expect(visitUrl).not.toHaveBeenCalled();
      expect(wrapper.vm.setError).toHaveBeenCalled();
    });
  });
});
