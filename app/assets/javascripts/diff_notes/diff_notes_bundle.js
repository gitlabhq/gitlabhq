/* eslint-disable func-names, comma-dangle, new-cap, no-new, max-len */
/* global ResolveCount */

import Vue from 'vue';
import resolveBtn from './components/resolve_btn.vue';
import './models/discussion';
import './models/note';
import './stores/comments';
import './services/resolve';
import './mixins/discussion';
import './components/comment_resolve_btn';
import './components/jump_to_discussion';
// import './components/resolve_btn';
import './components/resolve_count';
import './components/resolve_discussion_btn';
import './components/diff_note_avatars';
import './components/new_issue_for_discussion';

$(() => {
  const projectPath = document.querySelector('.merge-request').dataset.projectPath;
  const COMPONENT_SELECTOR = 'resolve-discussion-btn, jump-to-discussion, comment-and-resolve-btn, new-issue-for-discussion-btn';
  const ResolveBtnComponent = Vue.extend(resolveBtn);

  window.gl = window.gl || {};
  window.gl.diffNoteApps = {};

  window.ResolveService = new gl.DiffNotesResolveServiceClass(projectPath);

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
    const resolveBtns = document.querySelectorAll('.js-resolve-btn-mount');

    if ($components) {
      $components.each(function () {
        const $this = $(this);
        const noteId = $this.attr(':note-id');
        const tmp = Vue.extend({
          template: $this.get(0).outerHTML
        });
        const tmpApp = new tmp().$mount();

        if (noteId) {
          gl.diffNoteApps[`note_${noteId}`] = tmpApp;
        }

        $this.replaceWith(tmpApp.$el);
      });
    }

    if (resolveBtns) {
      resolveBtns.forEach((el) => {
        const {
          discussionId,
          noteId,
          resolved,
          canResolve,
          authorName,
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
            noteTruncated,
            resolvedBy,
          },
        }).$mount(el);

        if (noteId) {
          gl.diffNoteApps[`note_${noteId}`] = tmpApp;
        }
      });
    }
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
