<script>
import { GlLoadingIcon } from '@gitlab/ui';
import ciHeader from '../../vue_shared/components/header_ci_component.vue';
import eventHub from '../event_hub';

export default {
  name: 'PipelineHeaderSection',
  components: {
    ciHeader,
    GlLoadingIcon,
  },
  props: {
    pipeline: {
      type: Object,
      required: true,
    },
    isLoading: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      actions: this.getActions(),
    };
  },

  computed: {
    status() {
      return this.pipeline.details && this.pipeline.details.status;
    },
    shouldRenderContent() {
      return !this.isLoading && Object.keys(this.pipeline).length;
    },
  },

  watch: {
    pipeline() {
      this.actions = this.getActions();
    },
  },

  methods: {
    postAction(action) {
      const index = this.actions.indexOf(action);

      this.$set(this.actions[index], 'isLoading', true);

      eventHub.$emit('headerPostAction', action);
    },

    getActions() {
      const actions = [];

      if (this.pipeline.retry_path) {
        actions.push({
          label: 'Retry',
          path: this.pipeline.retry_path,
          cssClass: 'js-retry-button btn btn-inverted-secondary',
          type: 'button',
          isLoading: false,
        });
      }

      if (this.pipeline.cancel_path) {
        actions.push({
          label: 'Cancel running',
          path: this.pipeline.cancel_path,
          cssClass: 'js-btn-cancel-pipeline btn btn-danger',
          type: 'button',
          isLoading: false,
        });
      }

      return actions;
    },
  },
};
</script>
<template>
  <div class="pipeline-header-container">
    <ci-header
      v-if="shouldRenderContent"
      :status="status"
      :item-id="pipeline.id"
      :item-iid="pipeline.iid"
      :item-id-tooltip="__('Pipeline ID (IID)')"
      :time="pipeline.created_at"
      :user="pipeline.user"
      :actions="actions"
      item-name="Pipeline"
      @actionClicked="postAction"
    />
    <gl-loading-icon v-if="isLoading" :size="2" class="prepend-top-default append-bottom-default" />
  </div>
</template>
