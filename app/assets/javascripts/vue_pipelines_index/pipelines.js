/* global Vue, gl */
/* eslint-disable no-param-reassign */
import pipelinesEmptyStateSVG from 'empty_states/icons/_pipelines_empty.svg';
import pipelinesErrorStateSVG from 'empty_states/icons/_pipelines_failed.svg';

window.Vue = require('vue');
require('../vue_shared/components/table_pagination');
require('./store');
require('../vue_shared/components/pipelines_table');
const CommitPipelinesStoreWithTimeAgo = require('../commit/pipelines/pipelines_store');

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
        count: {},
        pageRequest: false,
        hasError: false,
        pipelinesEmptyStateSVG,
        pipelinesErrorStateSVG,
      };
    },
    props: ['scope', 'store'],
    created() {
      const pagenum = gl.utils.getParameterByName('page');
      const scope = gl.utils.getParameterByName('scope');
      if (pagenum) this.pagenum = pagenum;
      if (scope) this.apiScope = scope;

      this.store.fetchDataLoop.call(this, Vue, this.pagenum, this.scope, this.apiScope);
    },

    beforeUpdate() {
      if (this.pipelines.length && this.$children) {
        CommitPipelinesStoreWithTimeAgo.startTimeAgoLoops.call(this, Vue);
      }
    },

    computed: {
      shouldRenderErrorState() {
        return this.hasError && !this.pageRequest;
      },

      shouldRenderEmptyState() {
        return !this.hasError && !this.pageRequest && !this.pipelines.length;
      },
    },

    methods: {
      /**
       * Will change the page number and update the URL.
       *
       * @param  {Number} pageNumber desired page to go to.
       */
      change(pageNumber) {
        const param = gl.utils.setParamInURL('page', pageNumber);

        gl.utils.visitUrl(param);
        return param;
      },
    },
    template: `
      <div>
        <div class="pipelines realtime-loading" v-if='pageRequest'>
          <i class="fa fa-spinner fa-spin"></i>
        </div>

        <div v-if="shouldRenderEmptyState"
          class="row empty-state">

          <div class="col-xs-12 pull-right">
            <div class="svg-content">
              ${pipelinesEmptyStateSVG}
            </div>
          </div>

          <div class="col-xs-12 center">
            <div class="text-content">
              <h4>Build with confidence</h4>
              <p>
                Continous Integration can help catch bugs by running your tests automatically,
                while Continuous Deployment can help you deliver code to your product environment.

                <a href="" class="btn btn-info">
                  Get started with Pipelines
                </a>
              </p>
            </div>
          </div>
        </div>

        <div v-if="shouldRenderErrorState"
          class="row empty-state">

          <div class="col-xs-12 pull-right">
            <div class="svg-content">
              ${pipelinesErrorStateSVG}
            </div>
          </div>

          <div class="col-xs-12 center">
            <div class="text-content">
              <h4>The API failed to fetch the pipelines.</h4>
            </div>
          </div>
        </div>

        <div class="table-holder" v-if='!pageRequest && pipelines.length'>
          <pipelines-table-component :pipelines='pipelines'/>
        </div>

        <gl-pagination
          v-if='!pageRequest && pipelines.length && pageInfo.total > pageInfo.perPage'
          :pagenum='pagenum'
          :change='change'
          :count='count.all'
          :pageInfo='pageInfo'/>
      </div>
    `,
  });
})(window.gl || (window.gl = {}));
