/* eslint-disable func-names, comma-dangle, new-cap, no-new, max-len */
/* global ResolveCount */

import Vue from 'vue';
import resolveBtn from './components/resolve_btn.vue';
import resolveDiscussionBtn from './components/resolve_discussion_btn.vue';
import jumpToDiscussionBtn from './components/jump_to_discussion.vue';
import './models/discussion';
import './models/note';
import './stores/comments';
import './services/resolve';
import './mixins/discussion';
import './components/comment_resolve_btn';
import './components/resolve_count';
import './components/diff_note_avatars';
import './components/new_issue_for_discussion';

$(() => {
  const projectPath = document.querySelector('.merge-request').dataset.projectPath;
  const COMPONENT_SELECTOR = 'comment-and-resolve-btn, new-issue-for-discussion-btn';
  const ResolveBtnComponent = Vue.extend(resolveBtn);
  const ResolveDiscussionBtn = Vue.extend(resolveDiscussionBtn);
  const JumpToDiscussionBtn = Vue.extend(jumpToDiscussionBtn);

  window.gl = window.gl || {};
  window.gl.diffNoteApps = {};

  window.ResolveService = new gl.DiffNotesResolveServiceClass(projectPath);

  const compileResolveBtns = () => {
    const resolveBtns = document.querySelectorAll('.js-resolve-btn-mount');

    if (resolveBtns) {
      resolveBtns.forEach((el) => {
        const {
          discussionId,
          noteId,
          resolved,
          canResolve,
          authorName,
          authorAvatar,
          noteTruncated,
          resolvedBy,
        } = el.dataset;
        const tmpApp = new ResolveBtnComponent({
          propsData: {
            discussionId,
            noteId: parseInt(noteId, 10),
            resolved: gl.utils.convertPermissionToBoolean(resolved),
            canResolve: gl.utils.convertPermissionToBoolean(canResolve),
            authorName,
            authorAvatar,
            noteTruncated,
            resolvedBy,
          },
        }).$mount(el);

        if (noteId) {
          gl.diffNoteApps[`note_${noteId}`] = tmpApp;
        }
      });
    }
  };

  const compileResolveDiscussionBtns = () => {
    const discussionBtns = document.querySelectorAll('.js-resolve-discussion-btn');

    if (discussionBtns) {
      discussionBtns.forEach((el) => {
        const {
          discussionId,
          mergeRequestId,
          canResolve,
        } = el.dataset;
        return new ResolveDiscussionBtn({
          propsData: {
            discussionId,
            mergeRequestId: parseInt(mergeRequestId, 10),
            canResolve: gl.utils.convertPermissionToBoolean(canResolve),
          },
        }).$mount(el);
      });
    }
  };

  const compileJumpDiscussionBtn = () => {
    const jumpBtns = document.querySelectorAll('.js-jump-to-discussion');

    if (jumpBtns) {
      jumpBtns.forEach(el => new JumpToDiscussionBtn({
        propsData: {
          discussionId: el.dataset.discussionId,
        },
      }).$mount(el));
    }
  };

  gl.diffNotesCompileComponents = () => {
    console.time('diffNotesCompileComponents');
    $('diff-note-avatars').each(function () {
      const tmp = Vue.extend({
        template: $(this).get(0).outerHTML
      });
      const tmpApp = new tmp().$mount();

      $(this).replaceWith(tmpApp.$el);
    });

    const $components = $(COMPONENT_SELECTOR).filter(function () {
      return $(this).closest('resolve-count').length !== 1;
    });

    if ($components) {
      $components.each(function () {
        const $this = $(this);
        const tmp = Vue.extend({
          template: $this.get(0).outerHTML
        });
        return new tmp().$mount(this);
      });
    }

    compileResolveBtns();
    compileResolveDiscussionBtns();
    compileJumpDiscussionBtn();
    console.timeEnd('diffNotesCompileComponents');
  };

  gl.diffNotesCompileComponents();

  new Vue({
    el: '#resolve-count-app',
    components: {
      'resolve-count': ResolveCount
    }
  });

  $(window).trigger('resize.nav');
});
