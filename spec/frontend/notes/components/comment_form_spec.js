import $ from 'jquery';
import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import Autosize from 'autosize';
import { trimText } from 'helpers/text_helper';
import axios from '~/lib/utils/axios_utils';
import createStore from '~/notes/stores';
import CommentForm from '~/notes/components/comment_form.vue';
import * as constants from '~/notes/constants';
import { refreshUserMergeRequestCounts } from '~/commons/nav/user_merge_requests';
import { keyboardDownEvent } from '../../issue_show/helpers';
import {
  loggedOutnoteableData,
  notesDataMock,
  userDataMock,
  noteableDataMock,
} from '../../notes/mock_data';

jest.mock('autosize');
jest.mock('~/commons/nav/user_merge_requests');
jest.mock('~/gl_form');

describe('issue_comment_form component', () => {
  let store;
  let wrapper;
  let axiosMock;

  const setupStore = (userData, noteableData) => {
    store.dispatch('setUserData', userData);
    store.dispatch('setNoteableData', noteableData);
    store.dispatch('setNotesData', notesDataMock);
  };

  const mountComponent = (noteableType = 'issue') => {
    wrapper = mount(CommentForm, {
      propsData: {
        noteableType,
      },
      store,
      sync: false,
      attachToDocument: true,
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
    beforeEach(() => {
      setupStore(userDataMock, noteableDataMock);

      mountComponent();
    });

    it('should render user avatar with link', () => {
      expect(wrapper.find('.timeline-icon .user-avatar-link').attributes('href')).toEqual(
        userDataMock.path,
      );
    });

    describe('handleSave', () => {
      it('should request to save note when note is entered', () => {
        wrapper.vm.note = 'hello world';
        jest.spyOn(wrapper.vm, 'saveNote').mockReturnValue(new Promise(() => {}));
        jest.spyOn(wrapper.vm, 'resizeTextarea');
        jest.spyOn(wrapper.vm, 'stopPolling');

        wrapper.vm.handleSave();

        expect(wrapper.vm.isSubmitting).toEqual(true);
        expect(wrapper.vm.note).toEqual('');
        expect(wrapper.vm.saveNote).toHaveBeenCalled();
        expect(wrapper.vm.stopPolling).toHaveBeenCalled();
        expect(wrapper.vm.resizeTextarea).toHaveBeenCalled();
      });

      it('should toggle issue state when no note', () => {
        jest.spyOn(wrapper.vm, 'toggleIssueState');

        wrapper.vm.handleSave();

        expect(wrapper.vm.toggleIssueState).toHaveBeenCalled();
      });

      it('should disable action button whilst submitting', done => {
        const saveNotePromise = Promise.resolve();
        wrapper.vm.note = 'hello world';
        jest.spyOn(wrapper.vm, 'saveNote').mockReturnValue(saveNotePromise);
        jest.spyOn(wrapper.vm, 'stopPolling');

        const actionButton = wrapper.find('.js-action-button');

        wrapper.vm.handleSave();

        wrapper.vm
          .$nextTick()
          .then(() => {
            expect(actionButton.vm.disabled).toBeTruthy();
          })
          .then(saveNotePromise)
          .then(wrapper.vm.$nextTick)
          .then(() => {
            expect(actionButton.vm.disabled).toBeFalsy();
          })
          .then(done)
          .catch(done.fail);
      });
    });

    describe('textarea', () => {
      it('should render textarea with placeholder', () => {
        expect(wrapper.find('.js-main-target-form textarea').attributes('placeholder')).toEqual(
          'Write a comment or drag your files here…',
        );
      });

      it('should make textarea disabled while requesting', done => {
        const $submitButton = $(wrapper.find('.js-comment-submit-button').element);
        wrapper.vm.note = 'hello world';
        jest.spyOn(wrapper.vm, 'stopPolling');
        jest.spyOn(wrapper.vm, 'saveNote').mockReturnValue(new Promise(() => {}));

        wrapper.vm.$nextTick(() => {
          // Wait for wrapper.vm.note change triggered. It should enable $submitButton.
          $submitButton.trigger('click');

          wrapper.vm.$nextTick(() => {
            // Wait for wrapper.isSubmitting triggered. It should disable textarea.
            expect(wrapper.find('.js-main-target-form textarea').attributes('disabled')).toBe(
              'disabled',
            );
            done();
          });
        });
      });

      it('should support quick actions', () => {
        expect(
          wrapper.find('.js-main-target-form textarea').attributes('data-supports-quick-actions'),
        ).toBe('true');
      });

      it('should link to markdown docs', () => {
        const { markdownDocsPath } = notesDataMock;

        expect(
          wrapper
            .find(`a[href="${markdownDocsPath}"]`)
            .text()
            .trim(),
        ).toEqual('Markdown');
      });

      it('should link to quick actions docs', () => {
        const { quickActionsDocsPath } = notesDataMock;

        expect(
          wrapper
            .find(`a[href="${quickActionsDocsPath}"]`)
            .text()
            .trim(),
        ).toEqual('quick actions');
      });

      it('should resize textarea after note discarded', done => {
        jest.spyOn(wrapper.vm, 'discard');

        wrapper.vm.note = 'foo';
        wrapper.vm.discard();

        wrapper.vm.$nextTick(() => {
          expect(Autosize.update).toHaveBeenCalled();
          done();
        });
      });

      describe('edit mode', () => {
        it('should enter edit mode when arrow up is pressed', () => {
          jest.spyOn(wrapper.vm, 'editCurrentUserLastNote');
          wrapper.find('.js-main-target-form textarea').value = 'Foo';
          wrapper
            .find('.js-main-target-form textarea')
            .element.dispatchEvent(keyboardDownEvent(38, true));

          expect(wrapper.vm.editCurrentUserLastNote).toHaveBeenCalled();
        });

        it('inits autosave', () => {
          expect(wrapper.vm.autosave).toBeDefined();
          expect(wrapper.vm.autosave.key).toEqual(`autosave/Note/Issue/${noteableDataMock.id}`);
        });
      });

      describe('event enter', () => {
        it('should save note when cmd+enter is pressed', () => {
          jest.spyOn(wrapper.vm, 'handleSave');
          wrapper.find('.js-main-target-form textarea').value = 'Foo';
          wrapper
            .find('.js-main-target-form textarea')
            .element.dispatchEvent(keyboardDownEvent(13, true));

          expect(wrapper.vm.handleSave).toHaveBeenCalled();
        });

        it('should save note when ctrl+enter is pressed', () => {
          jest.spyOn(wrapper.vm, 'handleSave');
          wrapper.find('.js-main-target-form textarea').value = 'Foo';
          wrapper
            .find('.js-main-target-form textarea')
            .element.dispatchEvent(keyboardDownEvent(13, false, true));

          expect(wrapper.vm.handleSave).toHaveBeenCalled();
        });
      });
    });

    describe('actions', () => {
      it('should be possible to close the issue', () => {
        expect(
          wrapper
            .find('.btn-comment-and-close')
            .text()
            .trim(),
        ).toEqual('Close issue');
      });

      it('should render comment button as disabled', () => {
        expect(wrapper.find('.js-comment-submit-button').attributes('disabled')).toEqual(
          'disabled',
        );
      });

      it('should enable comment button if it has note', done => {
        wrapper.vm.note = 'Foo';
        wrapper.vm.$nextTick(() => {
          expect(wrapper.find('.js-comment-submit-button').attributes('disabled')).toBeFalsy();
          done();
        });
      });

      it('should update buttons texts when it has note', done => {
        wrapper.vm.note = 'Foo';
        wrapper.vm.$nextTick(() => {
          expect(
            wrapper
              .find('.btn-comment-and-close')
              .text()
              .trim(),
          ).toEqual('Comment & close issue');

          done();
        });
      });

      it('updates button text with noteable type', done => {
        wrapper.setProps({ noteableType: constants.MERGE_REQUEST_NOTEABLE_TYPE });

        wrapper.vm.$nextTick(() => {
          expect(
            wrapper
              .find('.btn-comment-and-close')
              .text()
              .trim(),
          ).toEqual('Close merge request');
          done();
        });
      });

      describe('when clicking close/reopen button', () => {
        it('should disable button and show a loading spinner', done => {
          const toggleStateButton = wrapper.find('.js-action-button');

          toggleStateButton.trigger('click');
          wrapper.vm.$nextTick(() => {
            expect(toggleStateButton.element.disabled).toEqual(true);
            expect(toggleStateButton.find('.js-loading-button-icon').exists()).toBe(true);

            done();
          });
        });
      });

      describe('when toggling state', () => {
        it('should update MR count', done => {
          jest.spyOn(wrapper.vm, 'closeIssue').mockResolvedValue();

          wrapper.vm.toggleIssueState();

          wrapper.vm.$nextTick(() => {
            expect(refreshUserMergeRequestCounts).toHaveBeenCalled();

            done();
          });
        });
      });
    });

    describe('issue is confidential', () => {
      it('shows information warning', done => {
        store.dispatch('setNoteableData', Object.assign(noteableDataMock, { confidential: true }));
        wrapper.vm.$nextTick(() => {
          expect(wrapper.find('.confidential-issue-warning')).toBeDefined();
          done();
        });
      });
    });
  });

  describe('user is not logged in', () => {
    beforeEach(() => {
      setupStore(null, loggedOutnoteableData);

      mountComponent();
    });

    it('should render signed out widget', () => {
      expect(trimText(wrapper.text())).toEqual('Please register or sign in to reply');
    });

    it('should not render submission form', () => {
      expect(wrapper.find('textarea').exists()).toBe(false);
    });
  });
});
