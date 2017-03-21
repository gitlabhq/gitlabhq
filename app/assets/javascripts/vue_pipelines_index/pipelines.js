/* global Flash */
/* eslint-disable no-new */
import '~/flash';
import Vue from 'vue';
import PipelinesService from './services/pipelines_service';
import eventHub from './event_hub';
import PipelinesTableComponent from '../vue_shared/components/pipelines_table';
import TablePaginationComponent from '../vue_shared/components/table_pagination';

export default {
  props: {
    endpoint: {
      type: String,
      required: true,
    },

    store: {
      type: Object,
      required: true,
    },
  },

  components: {
    'gl-pagination': TablePaginationComponent,
    'pipelines-table-component': PipelinesTableComponent,
  },

  data() {
    return {
      state: this.store.state,
      apiScope: 'all',
      pagenum: 1,
      pageRequest: false,
    };
  },

  created() {
    this.service = new PipelinesService(this.endpoint);

    this.fetchPipelines();

    eventHub.$on('refreshPipelines', this.fetchPipelines);
  },

  beforeUpdate() {
    if (this.state.pipelines.length && this.$children) {
      this.store.startTimeAgoLoops.call(this, Vue);
    }
  },

  beforeDestroyed() {
    eventHub.$off('refreshPipelines');
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

    fetchPipelines() {
      const pageNumber = gl.utils.getParameterByName('page') || this.pagenum;
      const scope = gl.utils.getParameterByName('scope') || this.apiScope;

      this.pageRequest = true;
      return this.service.getPipelines(scope, pageNumber)
        .then(resp => ({
          headers: resp.headers,
          body: resp.json(),
        }))
        .then((response) => {
          this.store.storeCount(response.body.count);
          this.store.storePipelines(response.body.pipelines);
          this.store.storePagination(response.headers);
        })
        .then(() => {
          this.pageRequest = false;
        })
        .catch(() => {
          this.pageRequest = false;
          new Flash('An error occurred while fetching the pipelines, please reload the page again.');
        });
    },
  },
  template: `
    <div>
      <div class="pipelines realtime-loading" v-if="pageRequest">
        <i class="fa fa-spinner fa-spin" aria-hidden="true"></i>
      </div>

      <div class="blank-state blank-state-no-icon"
        v-if="!pageRequest && state.pipelines.length === 0">
        <h2 class="blank-state-title js-blank-state-title">
          No pipelines to show
        </h2>
      </div>

      <div class="table-holder" v-if="!pageRequest && state.pipelines.length">
        <pipelines-table-component
          :pipelines="state.pipelines"
          :service="service"/>
      </div>

      <gl-pagination
        v-if="!pageRequest && state.pipelines.length && state.pageInfo.total > state.pageInfo.perPage"
        :pagenum="pagenum"
        :change="change"
        :count="state.count.all"
        :pageInfo="state.pageInfo"
      >
      </gl-pagination>
    </div>
  `,
};
