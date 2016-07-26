//= require vue
//= require vue-resource
//= require_directory ./stores
//= require_directory ./services
//= require_directory ./mixins
//= require_directory ./components

$(() => {
  window.DiffNotesApp = new Vue({
    el: '#diff-notes-app',
    components: {
      'resolve-btn': ResolveBtn,
      'resolve-all-btn': ResolveAllBtn,
      'resolve-comment-btn': ResolveCommentBtn,
    }
  });

  new Vue({
    el: '#resolve-count-app',
    components: {
      'resolve-count': ResolveCount
    }
  });
});
