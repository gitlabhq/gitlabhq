import { nextTick } from 'vue';
import { mount, shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import Autosize from 'autosize';
import axios from '~/lib/utils/axios_utils';
import createStore from '~/notes/stores';
import CommentForm from '~/notes/components/comment_form.vue';
import * as constants from '~/notes/constants';
import eventHub from '~/notes/event_hub';
import { refreshUserMergeRequestCounts } from '~/commons/nav/user_merge_requests';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import { loggedOutnoteableData, notesDataMock, userDataMock, noteableDataMock } from '../mock_data';

jest.mock('autosize');
jest.mock('~/commons/nav/user_merge_requests');
jest.mock('~/gl_form');

describe('issue_comment_form component', () => {
  let store;
  let wrapper;
  let axiosMock;

  const findCloseReopenButton = () => wrapper.find('[data-testid="close-reopen-button"]');

  const findCommentButton = () => wrapper.find('[data-testid="comment-button"]');

  const findTextArea = () => wrapper.find('[data-testid="comment-field"]');

  const mountComponent = ({
    initialData = {},
    noteableType = 'issue',
    noteableData = noteableDataMock,
    notesData = notesDataMock,
    userData = userDataMock,
    mountFunction = shallowMount,
  } = {}) => {
    store.dispatch('setNoteableData', noteableData);
    store.dispatch('setNotesData', notesData);
    store.dispatch('setUserData', userData);

    wrapper = mountFunction(CommentForm, {
      propsData: {
        noteableType,
      },
      data() {
        return {
          ...initialData,
        };
      },
      store,
    });
  };

  beforeEach(() => {
    axiosMock = new MockAdapter(axios);
    store = createStore();
  });

  afterEach(() => {
    axiosMock.restore();
    wrapper.destroy();
  });

  describe('user is logged in', () => {
    describe('avatar', () => {
      it('should render user avatar with link', () => {
        mountComponent({ mountFunction: mount });

        expect(wrapper.find(UserAvatarLink).attributes('href')).toBe(userDataMock.path);
      });
    });

    describe('handleSave', () => {
      it('should request to save note when note is entered', () => {
        mountComponent({ mountFunction: mount, initialData: { note: 'hello world' } });

        jest.spyOn(wrapper.vm, 'saveNote').mockResolvedValue();
        jest.spyOn(wrapper.vm, 'resizeTextarea');
        jest.spyOn(wrapper.vm, 'stopPolling');

        findCloseReopenButton().trigger('click');

        expect(wrapper.vm.isSubmitting).toBe(true);
        expect(wrapper.vm.note).toBe('');
        expect(wrapper.vm.saveNote).toHaveBeenCalled();
        expect(wrapper.vm.stopPolling).toHaveBeenCalled();
        expect(wrapper.vm.resizeTextarea).toHaveBeenCalled();
      });

      it('should toggle issue state when no note', () => {
        mountComponent({ mountFunction: mount });

        jest.spyOn(wrapper.vm, 'toggleIssueState');

        findCloseReopenButton().trigger('click');

        expect(wrapper.vm.toggleIssueState).toHaveBeenCalled();
      });

      it('should disable action button while submitting', async () => {
        mountComponent({ mountFunction: mount, initialData: { note: 'hello world' } });

        const saveNotePromise = Promise.resolve();

        jest.spyOn(wrapper.vm, 'saveNote').mockReturnValue(saveNotePromise);
        jest.spyOn(wrapper.vm, 'stopPolling');

        const actionButton = findCloseReopenButton();

        await actionButton.trigger('click');

        expect(actionButton.props('disabled')).toBe(true);

        await saveNotePromise;

        await nextTick();

        expect(actionButton.props('disabled')).toBe(false);
      });
    });

    describe('textarea', () => {
      describe('general', () => {
        it('should render textarea with placeholder', () => {
          mountComponent({ mountFunction: mount });

          expect(findTextArea().attributes('placeholder')).toBe(
            'Write a comment or drag your files here…',
          );
        });

        it('should make textarea disabled while requesting', async () => {
          mountComponent({ mountFunction: mount });

          jest.spyOn(wrapper.vm, 'stopPolling');
          jest.spyOn(wrapper.vm, 'saveNote').mockResolvedValue();

          await wrapper.setData({ note: 'hello world' });

          await findCommentButton().trigger('click');

          expect(findTextArea().attributes('disabled')).toBe('disabled');
        });

        it('should support quick actions', () => {
          mountComponent({ mountFunction: mount });

          expect(findTextArea().attributes('data-supports-quick-actions')).toBe('true');
        });

        it('should link to markdown docs', () => {
          mountComponent({ mountFunction: mount });

          const { markdownDocsPath } = notesDataMock;

          expect(wrapper.find(`a[href="${markdownDocsPath}"]`).text()).toBe('Markdown');
        });

        it('should link to quick actions docs', () => {
          mountComponent({ mountFunction: mount });

          const { quickActionsDocsPath } = notesDataMock;

          expect(wrapper.find(`a[href="${quickActionsDocsPath}"]`).text()).toBe('quick actions');
        });

        it('should resize textarea after note discarded', async () => {
          mountComponent({ mountFunction: mount, initialData: { note: 'foo' } });

          jest.spyOn(wrapper.vm, 'discard');

          wrapper.vm.discard();

          await nextTick();

          expect(Autosize.update).toHaveBeenCalled();
        });
      });

      describe('edit mode', () => {
        beforeEach(() => {
          mountComponent();
        });

        it('should enter edit mode when arrow up is pressed', () => {
          jest.spyOn(wrapper.vm, 'editCurrentUserLastNote');

          findTextArea().trigger('keydown.up');

          expect(wrapper.vm.editCurrentUserLastNote).toHaveBeenCalled();
        });

        it('inits autosave', () => {
          expect(wrapper.vm.autosave).toBeDefined();
          expect(wrapper.vm.autosave.key).toBe(`autosave/Note/Issue/${noteableDataMock.id}`);
        });
      });

      describe('event enter', () => {
        beforeEach(() => {
          mountComponent();
        });

        it('should save note when cmd+enter is pressed', () => {
          jest.spyOn(wrapper.vm, 'handleSave');

          findTextArea().trigger('keydown.enter', { metaKey: true });

          expect(wrapper.vm.handleSave).toHaveBeenCalled();
        });

        it('should save note when ctrl+enter is pressed', () => {
          jest.spyOn(wrapper.vm, 'handleSave');

          findTextArea().trigger('keydown.enter', { ctrlKey: true });

          expect(wrapper.vm.handleSave).toHaveBeenCalled();
        });
      });
    });

    describe('actions', () => {
      it('should be possible to close the issue', () => {
        mountComponent();

        expect(findCloseReopenButton().text()).toBe('Close issue');
      });

      it('should render comment button as disabled', () => {
        mountComponent();

        expect(findCommentButton().props('disabled')).toBe(true);
      });

      it('should enable comment button if it has note', async () => {
        mountComponent();

        await wrapper.setData({ note: 'Foo' });

        expect(findCommentButton().props('disabled')).toBe(false);
      });

      it('should update buttons texts when it has note', () => {
        mountComponent({ initialData: { note: 'Foo' } });

        expect(findCloseReopenButton().text()).toBe('Comment & close issue');
      });

      it('updates button text with noteable type', () => {
        mountComponent({ noteableType: constants.MERGE_REQUEST_NOTEABLE_TYPE });

        expect(findCloseReopenButton().text()).toBe('Close merge request');
      });

      describe('when clicking close/reopen button', () => {
        it('should show a loading spinner', async () => {
          mountComponent({
            noteableType: constants.MERGE_REQUEST_NOTEABLE_TYPE,
            mountFunction: mount,
          });

          await findCloseReopenButton().trigger('click');

          expect(findCloseReopenButton().props('loading')).toBe(true);
        });
      });

      describe('when toggling state', () => {
        describe('when issue', () => {
          it('emits event to toggle state', () => {
            mountComponent({ mountFunction: mount });

            jest.spyOn(eventHub, '$emit');

            findCloseReopenButton().trigger('click');

            expect(eventHub.$emit).toHaveBeenCalledWith('toggle.issuable.state');
          });
        });

        describe('when merge request', () => {
          describe('when open', () => {
            it('makes an API call to open the merge request', () => {
              mountComponent({
                noteableType: constants.MERGE_REQUEST_NOTEABLE_TYPE,
                noteableData: { ...noteableDataMock, state: constants.OPENED },
                mountFunction: mount,
              });

              jest.spyOn(wrapper.vm, 'closeMergeRequest').mockResolvedValue();

              findCloseReopenButton().trigger('click');

              expect(wrapper.vm.closeMergeRequest).toHaveBeenCalled();
            });
          });

          describe('when closed', () => {
            it('makes an API call to close the merge request', () => {
              mountComponent({
                noteableType: constants.MERGE_REQUEST_NOTEABLE_TYPE,
                noteableData: { ...noteableDataMock, state: constants.CLOSED },
                mountFunction: mount,
              });

              jest.spyOn(wrapper.vm, 'reopenMergeRequest').mockResolvedValue();

              findCloseReopenButton().trigger('click');

              expect(wrapper.vm.reopenMergeRequest).toHaveBeenCalled();
            });
          });

          it('should update MR count', async () => {
            mountComponent({
              noteableType: constants.MERGE_REQUEST_NOTEABLE_TYPE,
              mountFunction: mount,
            });

            jest.spyOn(wrapper.vm, 'closeMergeRequest').mockResolvedValue();

            await findCloseReopenButton().trigger('click');

            expect(refreshUserMergeRequestCounts).toHaveBeenCalled();
          });
        });
      });
    });

    describe('issue is confidential', () => {
      it('shows information warning', () => {
        mountComponent({
          noteableData: { ...noteableDataMock, confidential: true },
          mountFunction: mount,
        });

        expect(wrapper.find('[data-testid="confidential-warning"]').exists()).toBe(true);
      });
    });
  });

  describe('user is not logged in', () => {
    beforeEach(() => {
      mountComponent({ userData: null, noteableData: loggedOutnoteableData, mountFunction: mount });
    });

    it('should render signed out widget', () => {
      expect(wrapper.text()).toBe('Please register or sign in to reply');
    });

    it('should not render submission form', () => {
      expect(findTextArea().exists()).toBe(false);
    });
  });

  describe('close/reopen button variants', () => {
    it.each([
      [constants.OPENED, 'warning'],
      [constants.REOPENED, 'warning'],
      [constants.CLOSED, 'default'],
    ])('when %s, the variant of the btn is %s', (state, expected) => {
      mountComponent({ noteableData: { ...noteableDataMock, state } });

      expect(findCloseReopenButton().props('variant')).toBe(expected);
    });
  });
});
