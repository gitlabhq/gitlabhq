<script>
  import PipelinesService from '../../pipelines/services/pipelines_service';
  import PipelineStore from '../../pipelines/stores/pipelines_store';
  import pipelinesMixin from '../../pipelines/mixins/pipelines';

  export default {
    props: {
      endpoint: {
        type: String,
        required: true,
      },
      helpPagePath: {
        type: String,
        required: true,
      },
    },
    mixins: [
      pipelinesMixin,
    ],

    data() {
      const store = new PipelineStore();

      return {
        store,
        state: store.state,
      };
    },

    computed: {
      /**
       * Empty state is only rendered if after the first request we receive no pipelines.
       *
       * @return {Boolean}
       */
      shouldRenderEmptyState() {
        return !this.state.pipelines.length &&
          !this.isLoading &&
          this.hasMadeRequest &&
          !this.hasError;
      },

      shouldRenderTable() {
        return !this.isLoading &&
          this.state.pipelines.length > 0 &&
          !this.hasError;
      },
    },
    created() {
      this.service = new PipelinesService(this.endpoint);
    },
    methods: {
      successCallback(resp) {
        return resp.json().then((response) => {
          // depending of the endpoint the response can either bring a `pipelines` key or not.
          const pipelines = response.pipelines || response;
          this.setCommonData(pipelines);

          const updatePipelinesEvent = new CustomEvent('update-pipelines-count', {
            detail: {
              pipelines: response,
            },
          });

          // notifiy to update the count in tabs
          if (this.$el.parentElement) {
            this.$el.parentElement.dispatchEvent(updatePipelinesEvent);
          }
        });
      },
    },
  };
</script>
<template>
  <div class="content-list pipelines">

    <loading-icon
      label="Loading pipelines"
      size="3"
      v-if="isLoading"
      />

    <empty-state
      v-if="shouldRenderEmptyState"
      :help-page-path="helpPagePath"
      />

    <error-state
      v-if="shouldRenderErrorState"
      />

    <div
      class="table-holder"
      v-if="shouldRenderTable">
      <pipelines-table-component
        :pipelines="state.pipelines"
        :update-graph-dropdown="updateGraphDropdown"
        />
    </div>
  </div>
</template>
