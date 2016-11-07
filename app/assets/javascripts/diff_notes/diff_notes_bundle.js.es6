/* eslint-disable */
//= require vue
//= require vue-resource
//= require_directory ./models
//= require_directory ./stores
//= require_directory ./services
//= require_directory ./mixins
//= require_directory ./components

$(() => {
  window.DiffNotesApp = new Vue({
    el: '#diff-notes-app',
    methods: {
      compileComponents: function () {
        const $components = $('resolve-btn, resolve-discussion-btn, jump-to-discussion, comment-and-resolve-btn');

        if ($components.length) {
          $components.each(function () {
            const $this = $(this);
            const tmp = Vue.extend({
              template: $this.get(0).outerHTML,
              parent: DiffNotesApp,
            });
            $this.replaceWith(new tmp().$mount().$el);
          });
        }
      }
    }
  });

  new Vue({
    el: '#resolve-count-app',
    components: {
      'resolve-count': ResolveCount
    }
  });
});
