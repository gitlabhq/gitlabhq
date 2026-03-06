import { GlModal, GlForm } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import setWindowLocation from 'helpers/set_window_location_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createControlledMockApollo } from 'helpers/mock_apollo_helper';

import BoardForm from '~/boards/components/board_form.vue';
import { formType } from '~/boards/constants';
import createBoardMutation from '~/boards/graphql/board_create.mutation.graphql';
import destroyBoardMutation from '~/boards/graphql/board_destroy.mutation.graphql';
import updateBoardMutation from '~/boards/graphql/board_update.mutation.graphql';
import * as cacheUpdates from '~/boards/graphql/cache_updates';
import { visitUrl } from '~/lib/utils/url_utility';

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn().mockName('visitUrlMock'),
}));

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
  let requestHandlers;
  let mockApollo;

  Vue.use(VueApollo);

  const findModal = () => wrapper.findComponent(GlModal);
  const findModalActionPrimary = () => findModal().props('actionPrimary');
  const findForm = () => wrapper.findByTestId('board-form');
  const findFormWrapper = () => wrapper.findByTestId('board-form-wrapper');
  const findDeleteConfirmation = () => wrapper.findByTestId('delete-confirmation-message');
  const findDeleteLastBoardMessage = () => wrapper.findByTestId('delete-last-board-message');
  const findInput = () => wrapper.find('#board-new-name');
  const findInputFormWrapper = () => wrapper.findComponent(GlForm);
  const findDeleteButton = () => wrapper.findByTestId('delete-board-button');

  const defaultHandlers = {
    createBoardMutationHandler: jest.fn().mockResolvedValue({
      data: {
        createBoard: {
          board: { id: '1' },
          errors: [],
        },
      },
    }),
    destroyBoardMutationHandler: jest.fn().mockResolvedValue({
      data: {
        destroyBoard: {
          board: { id: '1' },
        },
      },
    }),
    updateBoardMutationHandler: jest.fn().mockResolvedValue({
      data: {
        updateBoard: { board: { id: 'gid://gitlab/Board/321', webPath: 'test-path' }, errors: [] },
      },
    }),
  };

  const createComponent = ({
    props,
    provide,
    handlers = defaultHandlers,
    stubs = { GlForm },
  } = {}) => {
    requestHandlers = handlers;
    mockApollo = createControlledMockApollo([
      [createBoardMutation, handlers.createBoardMutationHandler],
      [destroyBoardMutation, handlers.destroyBoardMutationHandler],
      [updateBoardMutation, handlers.updateBoardMutationHandler],
    ]);
    wrapper = shallowMountExtended(BoardForm, {
      apolloProvider: mockApollo.apolloProvider,
      propsData: { ...defaultProps, ...props },
      provide: {
        boardBaseUrl: 'root',
        isGroupBoard: true,
        isProjectBoard: false,
        ...provide,
      },
      attachTo: document.body,
      stubs,
    });
  };

  beforeEach(() => {
    cacheUpdates.setError = jest.fn();
  });

  describe('when user can not admin the board', () => {
    beforeEach(async () => {
      await createComponent({
        props: { currentPage: formType.new },
      });
    });

    it('hides modal footer when user is not a board admin', () => {
      expect(findModal().attributes('hide-footer')).toBeDefined();
    });

    it('displays board scope title', () => {
      expect(findModal().attributes('title')).toBe('Board configuration');
    });

    it('does not display a form', () => {
      expect(findForm().exists()).toBe(false);
    });
  });

  describe('when user can admin the board', () => {
    beforeEach(async () => {
      await createComponent({
        props: { canAdminBoard: true, currentPage: formType.new },
      });
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
      beforeEach(async () => {
        await createComponent({
          props: { canAdminBoard: true, currentPage: formType.new },
        });
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
      const fillForm = async () => {
        await findInput().setValue('test');
        findInputFormWrapper().trigger('submit');
      };

      it('does not call API if board name is empty', async () => {
        await createComponent({
          props: { canAdminBoard: true, currentPage: formType.new },
        });
        findInputFormWrapper().trigger('submit');

        await waitForPromises();

        expect(requestHandlers.createBoardMutationHandler).not.toHaveBeenCalled();
      });

      it('calls a correct GraphQL mutation and sets board in state', async () => {
        await createComponent({
          props: { canAdminBoard: true, currentPage: formType.new },
        });

        await fillForm();

        await waitForPromises();

        expect(requestHandlers.createBoardMutationHandler).toHaveBeenCalledWith({
          input: expect.objectContaining({
            name: 'test',
          }),
        });

        await mockApollo.resolveMutation(createBoardMutation);
        expect(wrapper.emitted('addBoard')).toHaveLength(1);
      });

      it('sets error in state if GraphQL mutation fails', async () => {
        await createComponent({
          props: { canAdminBoard: true, currentPage: formType.new },
        });

        await fillForm();

        await waitForPromises();

        expect(requestHandlers.createBoardMutationHandler).toHaveBeenCalled();

        await mockApollo.rejectMutation(createBoardMutation, 'Houston, we have a problem');
        expect(cacheUpdates.setError).toHaveBeenCalled();
      });
    });
  });

  describe('when editing a board', () => {
    describe('on non-scoped-board', () => {
      beforeEach(async () => {
        await createComponent({
          props: { canAdminBoard: true, currentPage: formType.edit },
        });
      });

      it('clears the form', () => {
        expect(findInput().element.value).toEqual(currentBoard.name);
      });

      it('shows a correct title about creating a board', () => {
        expect(findModal().attributes('title')).toBe('Configure board');
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
      it('emits showBoardModal with delete when clicking on delete board button', async () => {
        await createComponent({
          props: {
            currentPage: formType.edit,
            showDelete: true,
            canAdminBoard: true,
          },
          stubs: { GlModal },
        });

        findDeleteButton().vm.$emit('click');
        expect(wrapper.emitted('showBoardModal')).toEqual([[formType.delete]]);
      });
    });

    it('calls GraphQL mutation with correct parameters when issues are not grouped', async () => {
      setWindowLocation('https://test/boards/1');
      await createComponent({
        props: { canAdminBoard: true, currentPage: formType.edit },
      });

      findInputFormWrapper().trigger('submit');

      await waitForPromises();

      expect(requestHandlers.updateBoardMutationHandler).toHaveBeenCalledWith({
        input: expect.objectContaining({
          id: currentBoard.id,
        }),
      });

      await mockApollo.resolveMutation(updateBoardMutation);
      expect(global.window.location.href).not.toContain('?group_by=epic');
      expect(wrapper.emitted('updateBoard')).toHaveLength(1);
      expect(wrapper.emitted('updateBoard')).toEqual([
        [
          {
            id: 'gid://gitlab/Board/321',
            webPath: 'test-path',
          },
        ],
      ]);
    });

    it('calls GraphQL mutation with correct parameters when issues are grouped by epic', async () => {
      setWindowLocation('https://test/boards/1?group_by=epic');
      await createComponent({
        props: { canAdminBoard: true, currentPage: formType.edit },
      });

      findInputFormWrapper().trigger('submit');

      await waitForPromises();

      expect(requestHandlers.updateBoardMutationHandler).toHaveBeenCalledWith({
        input: expect.objectContaining({
          id: currentBoard.id,
        }),
      });

      await mockApollo.resolveMutation(updateBoardMutation);
      expect(global.window.location.href).toContain('?group_by=epic');
    });

    it('sets error in state if GraphQL mutation fails', async () => {
      await createComponent({
        props: { canAdminBoard: true, currentPage: formType.edit },
      });

      findInputFormWrapper().trigger('submit');

      await waitForPromises();

      expect(requestHandlers.updateBoardMutationHandler).toHaveBeenCalled();

      await mockApollo.rejectMutation(updateBoardMutation, 'Houston, we have a problem');
      expect(cacheUpdates.setError).toHaveBeenCalled();
    });
  });

  describe('when deleting a board', () => {
    it('passes correct primary action text and variant', async () => {
      await createComponent({
        props: { canAdminBoard: true, currentPage: formType.delete },
      });
      expect(findModalActionPrimary().text).toBe('Delete');
      expect(findModalActionPrimary().attributes.variant).toBe('danger');
    });

    it('renders delete confirmation message', async () => {
      await createComponent({
        props: { canAdminBoard: true, currentPage: formType.delete },
      });
      expect(findDeleteConfirmation().exists()).toBe(true);
    });

    it('lets user know they are deleting the last board when isLastBoard is true', async () => {
      await createComponent({
        props: { canAdminBoard: true, currentPage: formType.delete, isLastBoard: true },
      });
      expect(findDeleteLastBoardMessage().exists()).toBe(true);
    });

    it.each`
      parentType   | expected
      ${'project'} | ${'project'}
      ${'group'}   | ${'group'}
      ${null}      | ${'Because this is the only board here'}
    `(
      'tells the user they are deleting the last board in the $expected when the parentType is $parentType',
      async ({ parentType, expected }) => {
        await createComponent({
          props: {
            canAdminBoard: true,
            currentPage: formType.delete,
            isLastBoard: true,
            parentType,
          },
        });
        expect(findDeleteLastBoardMessage().text()).toContain(expected);
      },
    );

    it('calls a correct GraphQL mutation and redirects to correct page after deleting board', async () => {
      await createComponent({
        props: { canAdminBoard: true, currentPage: formType.delete },
      });
      findModal().vm.$emit('primary', { preventDefault: jest.fn() });

      await waitForPromises();

      expect(requestHandlers.destroyBoardMutationHandler).toHaveBeenCalledWith({
        id: currentBoard.id,
      });

      await mockApollo.resolveMutation(destroyBoardMutation);
      expect(visitUrl).toHaveBeenCalledWith('root');
    });

    it('dispatches `setError` action when GraphQL mutation fails', async () => {
      await createComponent({
        props: { canAdminBoard: true, currentPage: formType.delete },
      });

      findModal().vm.$emit('primary', { preventDefault: jest.fn() });

      await waitForPromises();

      expect(requestHandlers.destroyBoardMutationHandler).toHaveBeenCalled();

      await mockApollo.rejectMutation(destroyBoardMutation, 'Houston, we have a problem');
      expect(visitUrl).not.toHaveBeenCalled();
      expect(cacheUpdates.setError).toHaveBeenCalledWith(
        expect.objectContaining({
          message: 'Failed to delete board. Please try again.',
        }),
      );
    });
  });
});
