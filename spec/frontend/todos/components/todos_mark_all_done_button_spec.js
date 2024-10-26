import { GlButton } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import markAllAsDoneMutation from '~/todos/components/mutations/mark_all_as_done.mutation.graphql';
import undoMarkAllAsDoneMutation from '~/todos/components/mutations/undo_mark_all_as_done.mutation.graphql';
import TodosMarkAllDoneButton from '~/todos/components/todos_mark_all_done_button.vue';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import {
  todosMarkAllAsDoneResponse,
  todosUndoMarkAllAsDoneResponse,
  todosMarkAllAsDoneErrorResponse,
  todosUndoMarkAllAsDoneErrorResponse,
} from '../mock_data';

Vue.use(VueApollo);

const markAllAsDoneMutationSuccessHandler = jest.fn().mockResolvedValue(todosMarkAllAsDoneResponse);
const undoMarkAllAsDoneMutationSuccessHandler = jest
  .fn()
  .mockResolvedValue(todosUndoMarkAllAsDoneResponse);
const markAllAsDoneMutationErrorHandler = jest
  .fn()
  .mockResolvedValue(todosMarkAllAsDoneErrorResponse);
const undoMarkAllAsDoneMutationErrorHandler = jest
  .fn()
  .mockResolvedValue(todosUndoMarkAllAsDoneErrorResponse);

describe('TodosMarkAllDoneButton', () => {
  let wrapper;
  let toastMock;

  function createComponent({
    props = {},
    data = {},
    markAllAsDoneMutationHandler = markAllAsDoneMutationSuccessHandler,
    undoMarkAllAsDoneMutationHandler = undoMarkAllAsDoneMutationSuccessHandler,
  } = {}) {
    const mockApollo = createMockApollo();
    mockApollo.defaultClient.setRequestHandler(markAllAsDoneMutation, markAllAsDoneMutationHandler);

    mockApollo.defaultClient.setRequestHandler(
      undoMarkAllAsDoneMutation,
      undoMarkAllAsDoneMutationHandler,
    );

    toastMock = {
      show: jest.fn().mockReturnValue({ hide: jest.fn() }),
    };

    wrapper = mount(TodosMarkAllDoneButton, {
      apolloProvider: mockApollo,
      propsData: {
        ...props,
      },
      data() {
        return data;
      },
      mocks: {
        $toast: toastMock,
      },
    });
  }

  const findButton = () => wrapper.findComponent(GlButton);
  const clickButton = () => findButton().trigger('click');

  it('is a button', () => {
    createComponent();
    expect(findButton().exists()).toBe(true);
  });

  describe('on click', () => {
    it('sets the loading state while processing', async () => {
      createComponent();

      expect(findButton().props('loading')).toBe(false);

      clickButton();
      await nextTick();

      expect(findButton().props('loading')).toBe(true);
    });

    it('emits instrumentation event', async () => {
      const trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
      createComponent();
      clickButton();

      await nextTick();

      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_todo_item_action', {
        label: 'mark_all_as_done',
      });
      unmockTracking();
    });

    it('marks all todos as done when clicked', async () => {
      createComponent();
      clickButton();

      await nextTick();

      expect(markAllAsDoneMutationSuccessHandler).toHaveBeenCalled();
    });

    it('forwards filters when available', async () => {
      createComponent({
        props: {
          filters: {
            authorId: 10,
          },
        },
      });
      clickButton();

      await nextTick();

      expect(markAllAsDoneMutationSuccessHandler).toHaveBeenCalledWith({ authorId: 10 });
    });

    it('shows a toast message on success', async () => {
      createComponent();
      clickButton();

      await waitForPromises();

      expect(toastMock.show).toHaveBeenCalledWith('Marked 2 to-dos as done', {
        action: {
          text: 'Undo',
          onClick: expect.anything(),
        },
      });
    });

    it('shows a toast on failure', async () => {
      createComponent({ markAllAsDoneMutationHandler: markAllAsDoneMutationErrorHandler });
      clickButton();

      await waitForPromises();

      expect(toastMock.show).toHaveBeenCalledWith('Mark all as done failed. Try again later.', {
        variant: 'danger',
      });
    });

    it('emits a "change" event', async () => {
      createComponent();
      clickButton();

      await waitForPromises();

      expect(wrapper.emitted('change')).toBeDefined();
    });
  });

  describe('when undoing', () => {
    const triggerUndo = async () => {
      clickButton();
      await waitForPromises();
      toastMock.show.mock.calls[0][1].action.onClick();
    };

    it('emits instrumentation event', async () => {
      const trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
      createComponent();

      await triggerUndo();
      await nextTick();

      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_todo_item_action', {
        label: 'undo_mark_all_as_done',
      });
      unmockTracking();
    });

    it('sets the loading state while processing', async () => {
      createComponent();

      expect(findButton().props('loading')).toBe(false);

      await triggerUndo();
      await nextTick();

      expect(findButton().props('loading')).toBe(true);
    });

    it('restores the todos', async () => {
      createComponent();
      await triggerUndo();
      await waitForPromises();

      expect(undoMarkAllAsDoneMutationSuccessHandler).toHaveBeenCalled();
    });

    it('shows a toast message on success', async () => {
      createComponent();
      await triggerUndo();

      await waitForPromises();

      expect(toastMock.show).toHaveBeenCalledWith('Restored 2 to-dos');
    });

    it('shows a toast on failure', async () => {
      createComponent({ undoMarkAllAsDoneMutationHandler: undoMarkAllAsDoneMutationErrorHandler });
      await triggerUndo();

      await waitForPromises();

      expect(toastMock.show).toHaveBeenCalledWith('Could not restore to-dos.', {
        variant: 'danger',
      });
    });

    it('emits a "change" event', async () => {
      createComponent();
      await triggerUndo();

      await waitForPromises();

      expect(wrapper.emitted('change')).toBeDefined();
    });
  });
});
