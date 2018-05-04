<script>
  import PipelinesService from '../../pipelines/services/pipelines_service';
  import PipelineStore from '../../pipelines/stores/pipelines_store';
  import pipelinesMixin from '../../pipelines/mixins/pipelines';

  export default {
    mixins: [
      pipelinesMixin,
    ],
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
      };
    },

    computed: {
      shouldRenderTable() {
        return !this.isLoading &&
          this.state.pipelines.length > 0 &&
          !this.hasError;
      },
      shouldRenderErrorState() {
        return this.hasError && !this.isLoading;
      },
    },
    created() {
      this.service = new PipelinesService(this.endpoint);
    },
    methods: {
      successCallback(resp) {
        // depending of the endpoint the response can either bring a `pipelines` key or not.
        const pipelines = resp.data.pipelines || resp.data;
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

    <loading-icon
      :label="s__('Pipelines|Loading Pipelines')"
      size="3"
      v-if="isLoading"
      class="prepend-top-20"
    />

    <svg-blank-state
      v-else-if="shouldRenderErrorState"
      :svg-path="errorStateSvgPath"
      :message="s__(`Pipelines|There was an error fetching the pipelines.
      Try again in a few moments or contact your support team.`)"
    />

    <div
      class="table-holder"
      v-else-if="shouldRenderTable"
    >
      <pipelines-table-component
        :pipelines="state.pipelines"
        :update-graph-dropdown="updateGraphDropdown"
        :auto-devops-help-path="autoDevopsHelpPath"
        :view-type="viewType"
      />
    </div>
  </div>
</template>
