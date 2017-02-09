/* eslint-disable func-names, comma-dangle, new-cap, no-new, import/newline-after-import, no-multi-spaces, max-len */
/* global Vue */
/* global ResolveCount */
/* global ResolveServiceClass */

function requireAll(context) { return context.keys().map(context); }
const Vue = require('vue');
requireAll(require.context('./models',     false, /^\.\/.*\.(js|es6)$/));
requireAll(require.context('./stores',     false, /^\.\/.*\.(js|es6)$/));
requireAll(require.context('./services',   false, /^\.\/.*\.(js|es6)$/));
requireAll(require.context('./mixins',     false, /^\.\/.*\.(js|es6)$/));
requireAll(require.context('./components', false, /^\.\/.*\.(js|es6)$/));

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
