/* eslint-disable func-names, comma-dangle, new-cap, no-new, max-len */
/* global Vue */
/* global ResolveCount */
/* global ResolveServiceClass */

const Vue = require('vue');
require('./models/discussion');
require('./models/note');
require('./stores/comments');
require('./services/resolve');
require('./mixins/discussion');
require('./components/comment_resolve_btn');
require('./components/jump_to_discussion');
require('./components/resolve_btn');
require('./components/resolve_count');
require('./components/resolve_discussion_btn');

$(() => {
  const projectPath = document.querySelector('.merge-request').dataset.projectPath;
  const COMPONENT_SELECTOR = 'resolve-btn, resolve-discussion-btn, jump-to-discussion, comment-and-resolve-btn';

  window.gl = window.gl || {};
  window.gl.diffNoteApps = {};

  window.ResolveService = new gl.DiffNotesResolveServiceClass(projectPath);

  gl.diffNotesCompileComponents = () => {
    const $components = $(COMPONENT_SELECTOR).filter(function () {
      return $(this).closest('resolve-count').length !== 1;
    });

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
  };

  gl.diffNotesCompileComponents();

  new Vue({
    el: '#resolve-count-app',
    components: {
      'resolve-count': ResolveCount
    },
  });
});
