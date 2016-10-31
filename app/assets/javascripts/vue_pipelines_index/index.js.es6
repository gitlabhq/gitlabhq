/* global Vue, VueResource, gl */

//= require vue
//= require vue-resource

//= require ./store.js.es6
//= require ./running_icon.vue.js.es6
//= require ./running.vue.js.es6
//= require ./pipelines.vue.js.es6

(() => {
  const project = document.querySelector('.table-holder');

  Vue.use(VueResource);

  return new Vue({
    el: '.vue-pipelines-index',
    data: {
      scope: project.dataset.projectId,
      store: new gl.PipelineStore(),
    },
    components: {
      'vue-pipelines': gl.VuePipeLines,
    },
    template: `
      <vue-pipelines :scope='scope' :store='store'></vue-pipelines>
    `,
  });
})();
