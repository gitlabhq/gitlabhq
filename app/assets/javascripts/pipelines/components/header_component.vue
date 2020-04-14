<script>
import { GlLoadingIcon, GlModal, GlModalDirective } from '@gitlab/ui';
import ciHeader from '~/vue_shared/components/header_ci_component.vue';
import LoadingButton from '~/vue_shared/components/loading_button.vue';
import eventHub from '../event_hub';
import { __ } from '~/locale';

const DELETE_MODAL_ID = 'pipeline-delete-modal';

export default {
  name: 'PipelineHeaderSection',
  components: {
    ciHeader,
    GlLoadingIcon,
    GlModal,
    LoadingButton,
  },
  directives: {
    GlModal: GlModalDirective,
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
      isCanceling: false,
      isRetrying: false,
      isDeleting: false,
    };
  },

  computed: {
    status() {
      return this.pipeline.details && this.pipeline.details.status;
    },
    shouldRenderContent() {
      return !this.isLoading && Object.keys(this.pipeline).length;
    },
    deleteModalConfirmationText() {
      return __(
        'Are you sure you want to delete this pipeline? Doing so will expire all pipeline caches and delete all related objects, such as builds, logs, artifacts, and triggers. This action cannot be undone.',
      );
    },
  },

  methods: {
    cancelPipeline() {
      this.isCanceling = true;
      eventHub.$emit('headerPostAction', this.pipeline.cancel_path);
    },
    retryPipeline() {
      this.isRetrying = true;
      eventHub.$emit('headerPostAction', this.pipeline.retry_path);
    },
    deletePipeline() {
      this.isDeleting = true;
      eventHub.$emit('headerDeleteAction', this.pipeline.delete_path);
    },
  },
  DELETE_MODAL_ID,
};
</script>
<template>
  <div class="pipeline-header-container">
    <ci-header
      v-if="shouldRenderContent"
      :status="status"
      :item-id="pipeline.id"
      :time="pipeline.created_at"
      :user="pipeline.user"
      item-name="Pipeline"
    >
      <loading-button
        v-if="pipeline.retry_path"
        :loading="isRetrying"
        :disabled="isRetrying"
        class="js-retry-button btn btn-inverted-secondary"
        container-class="d-inline"
        :label="__('Retry')"
        @click="retryPipeline()"
      />

      <loading-button
        v-if="pipeline.cancel_path"
        :loading="isCanceling"
        :disabled="isCanceling"
        class="js-btn-cancel-pipeline btn btn-danger"
        container-class="d-inline"
        :label="__('Cancel running')"
        @click="cancelPipeline()"
      />

      <loading-button
        v-if="pipeline.delete_path"
        v-gl-modal="$options.DELETE_MODAL_ID"
        :loading="isDeleting"
        :disabled="isDeleting"
        class="js-btn-delete-pipeline btn btn-danger btn-inverted"
        container-class="d-inline"
        :label="__('Delete')"
      />
    </ci-header>

    <gl-loading-icon v-if="isLoading" size="lg" class="prepend-top-default append-bottom-default" />

    <gl-modal
      :modal-id="$options.DELETE_MODAL_ID"
      :title="__('Delete pipeline')"
      :ok-title="__('Delete pipeline')"
      ok-variant="danger"
      @ok="deletePipeline()"
    >
      <p>
        {{ deleteModalConfirmationText }}
      </p>
    </gl-modal>
  </div>
</template>
