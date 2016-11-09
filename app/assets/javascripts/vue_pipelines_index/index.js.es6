/* global Vue, VueResource, gl */
/* eslint-disable no-bitwise*/

//= require vue-resource

//= require ./store.js.es6
//= require ./pipeline_url.js.es6
//= require ./pipeline_head.js.es6
//= require ./stages.js.es6
//= require ./pipeline_actions.js.es6
//= require ./branch_commit.js.es6
//= require ./time_ago.js.es6
//= require ./pipelines.js.es6

(() => {
  const url = window.location.href;
  if (~url.indexOf('scope')) return null;

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
