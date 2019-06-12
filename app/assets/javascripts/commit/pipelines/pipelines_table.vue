<script>
import PipelinesService from '../../pipelines/services/pipelines_service';
import PipelineStore from '../../pipelines/stores/pipelines_store';
import pipelinesMixin from '../../pipelines/mixins/pipelines';
import TablePagination from '../../vue_shared/components/pagination/table_pagination.vue';
import { getParameterByName } from '../../lib/utils/common_utils';
import CIPaginationMixin from '../../vue_shared/mixins/ci_pagination_api_mixin';

export default {
  components: {
    TablePagination,
  },
  mixins: [pipelinesMixin, CIPaginationMixin],
  props: {
    endpoint: {
      type: String,
      required: true,
    },
    helpPagePath: {
      type: String,
      required: true,
    },
    autoDevopsHelpPath: {
      type: String,
      required: true,
    },
    errorStateSvgPath: {
      type: String,
      required: true,
    },
    viewType: {
      type: String,
      required: false,
      default: 'child',
    },
  },

  data() {
    const store = new PipelineStore();

    return {
      store,
      state: store.state,
      page: getParameterByName('page') || '1',
      requestData: {},
    };
  },

  computed: {
    shouldRenderTable() {
      return !this.isLoading && this.state.pipelines.length > 0 && !this.hasError;
    },
    shouldRenderErrorState() {
      return this.hasError && !this.isLoading;
    },
  },
  created() {
    this.service = new PipelinesService(this.endpoint);
    this.requestData = { page: this.page };
  },
  methods: {
    successCallback(resp) {
      // depending of the endpoint the response can either bring a `pipelines` key or not.
      const pipelines = resp.data.pipelines || resp.data;

      this.store.storePagination(resp.headers);
      this.setCommonData(pipelines);

      const updatePipelinesEvent = new CustomEvent('update-pipelines-count', {
        detail: {
          pipelines: resp.data,
        },
      });

      // notifiy to update the count in tabs
      if (this.$el.parentElement) {
        this.$el.parentElement.dispatchEvent(updatePipelinesEvent);
      }
    },
  },
};
</script>
<template>
  <div class="content-list pipelines">
    <gl-loading-icon
      v-if="isLoading"
      :label="s__('Pipelines|Loading Pipelines')"
      :size="3"
      class="prepend-top-20"
    />

    <svg-blank-state
      v-else-if="shouldRenderErrorState"
      :svg-path="errorStateSvgPath"
      :message="
        s__(`Pipelines|There was an error fetching the pipelines.
      Try again in a few moments or contact your support team.`)
      "
    />

    <div v-else-if="shouldRenderTable" class="table-holder">
      <pipelines-table-component
        :pipelines="state.pipelines"
        :update-graph-dropdown="updateGraphDropdown"
        :auto-devops-help-path="autoDevopsHelpPath"
        :view-type="viewType"
      />
    </div>

    <table-pagination
      v-if="shouldRenderPagination"
      :change="onChangePage"
      :page-info="state.pageInfo"
    />
  </div>
</template>
