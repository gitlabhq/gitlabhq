/* global Vue, gl */
/* eslint-disable no-param-reassign */

window.Vue = require('vue');
require('../vue_shared/components/table_pagination');
require('./store');
require('../vue_shared/components/pipelines_table');

((gl) => {
  gl.VuePipelines = Vue.extend({

    components: {
      'gl-pagination': gl.VueGlPagination,
      'pipelines-table-component': gl.pipelines.PipelinesTableComponent,
    },

    data() {
      return {
        pipelines: [],
        timeLoopInterval: '',
        intervalId: '',
        apiScope: 'all',
        pageInfo: {},
        pagenum: 1,
        count: { all: 0, running_or_pending: 0 },
        pageRequest: false,
      };
    },
    props: ['scope', 'store', 'svgs'],
    created() {
      const pagenum = gl.utils.getParameterByName('p');
      const scope = gl.utils.getParameterByName('scope');
      if (pagenum) this.pagenum = pagenum;
      if (scope) this.apiScope = scope;
      this.store.fetchDataLoop.call(this, Vue, this.pagenum, this.scope, this.apiScope);
    },
    methods: {
      change(pagenum, apiScope) {
        gl.utils.visitUrl(`?scope=${apiScope}&p=${pagenum}`);
      },
    },
    template: `
      <div>
        <div class="pipelines realtime-loading" v-if='pageRequest'>
          <i class="fa fa-spinner fa-spin"></i>
        </div>

        <div class="blank-state blank-state-no-icon"
          v-if="!pageRequest && pipelines.length === 0">
          <h2 class="blank-state-title js-blank-state-title">
            No pipelines to show
          </h2>
        </div>

        <div class="table-holder" v-if='!pageRequest && pipelines.length'>
          <pipelines-table-component
            :pipelines='pipelines'
            :svgs='svgs'>
          </pipelines-table-component>
        </div>

        <gl-pagination
          v-if='!pageRequest && pipelines.length && pageInfo.total > pageInfo.perPage'
          :pagenum='pagenum'
          :change='change'
          :count='count.all'
          :pageInfo='pageInfo'
        >
        </gl-pagination>
      </div>
    `,
  });
})(window.gl || (window.gl = {}));
