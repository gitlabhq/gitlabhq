/* global Vue, VueResource, gl */

//= require vue
//= require vue-resource

//= require ./store.js.es6
//= require ./pipeline_url.vue.js.es6
//= require ./vue_gl_pagination.vue.js.es6
//= require ./pipeline_head.vue.js.es6
//= require ./running_icon.vue.js.es6
//= require ./running.vue.js.es6
//= require ./stages.vue.js.es6
//= require ./pipeline_actions.vue.js.es6
//= require ./branch_commit.vue.js.es6
//= require ./pipelines.vue.js.es6

(() => {
  const project = document.querySelector('.pipelines');

  Vue.use(VueResource);

  return new Vue({
    el: '.vue-pipelines-index',
    data: {
      scope: project.dataset.projectId,
      count: project.dataset.count,
      store: new gl.PipelineStore(),
    },
    components: {
      'vue-pipelines': gl.VuePipeLines,
    },
    template: `
      <div>
        <vue-pipelines
          :scope='scope'
          :store='store'
          :count='count'
        >
        </vue-pipelines>
      </div>
    `,
  });
})();
