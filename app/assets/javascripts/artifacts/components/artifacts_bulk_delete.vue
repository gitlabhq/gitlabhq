<script>
import { GlButton, GlModal, GlSprintf } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { TYPENAME_PROJECT } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import getJobArtifactsQuery from '../graphql/queries/get_job_artifacts.query.graphql';
import bulkDestroyJobArtifactsMutation from '../graphql/mutations/bulk_destroy_job_artifacts.mutation.graphql';
import { removeArtifactFromStore } from '../graphql/cache_update';
import {
  I18N_BULK_DELETE_BANNER,
  I18N_BULK_DELETE_CLEAR_SELECTION,
  I18N_BULK_DELETE_DELETE_SELECTED,
  I18N_BULK_DELETE_MODAL_TITLE,
  I18N_BULK_DELETE_BODY,
  I18N_BULK_DELETE_ACTION,
  I18N_BULK_DELETE_PARTIAL_ERROR,
  I18N_BULK_DELETE_ERROR,
  I18N_MODAL_CANCEL,
  BULK_DELETE_MODAL_ID,
} from '../constants';

export default {
  name: 'ArtifactsBulkDelete',
  components: {
    GlButton,
    GlModal,
    GlSprintf,
  },
  inject: ['projectId'],
  props: {
    selectedArtifacts: {
      type: Array,
      required: true,
    },
    queryVariables: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isModalVisible: false,
      isDeleting: false,
    };
  },
  computed: {
    checkedCount() {
      return this.selectedArtifacts.length || 0;
    },
    modalActionPrimary() {
      return {
        text: I18N_BULK_DELETE_ACTION(this.checkedCount),
        attributes: {
          loading: this.isDeleting,
          variant: 'danger',
        },
      };
    },
    modalActionCancel() {
      return {
        text: I18N_MODAL_CANCEL,
        attributes: {
          loading: this.isDeleting,
        },
      };
    },
  },
  methods: {
    async onConfirmDelete(e) {
      // don't close modal until deletion is complete
      if (e) {
        e.preventDefault();
      }
      this.isDeleting = true;

      try {
        await this.$apollo.mutate({
          mutation: bulkDestroyJobArtifactsMutation,
          variables: {
            projectId: convertToGraphQLId(TYPENAME_PROJECT, this.projectId),
            ids: this.selectedArtifacts,
          },
          update: (store, { data }) => {
            const { errors, destroyedCount, destroyedIds } = data.bulkDestroyJobArtifacts;
            if (errors?.length) {
              createAlert({
                message: I18N_BULK_DELETE_PARTIAL_ERROR,
                captureError: true,
                error: new Error(errors.join(' ')),
              });
            }
            if (destroyedIds?.length) {
              this.$emit('deleted', destroyedCount);

              // Remove deleted artifacts from the cache
              destroyedIds.forEach((id) => {
                removeArtifactFromStore(store, id, getJobArtifactsQuery, this.queryVariables);
              });
              store.gc();

              this.$emit('clearSelectedArtifacts');
            }
          },
        });
      } catch (error) {
        this.onError(error);
      } finally {
        this.isDeleting = false;
        this.isModalVisible = false;
      }
    },
    onError(error) {
      createAlert({
        message: I18N_BULK_DELETE_ERROR,
        captureError: true,
        error,
      });
    },
    handleClearSelection() {
      this.$emit('clearSelectedArtifacts');
    },
    handleModalShow() {
      this.isModalVisible = true;
    },
    handleModalHide() {
      this.isModalVisible = false;
    },
  },
  i18n: {
    banner: I18N_BULK_DELETE_BANNER,
    clearSelection: I18N_BULK_DELETE_CLEAR_SELECTION,
    deleteSelected: I18N_BULK_DELETE_DELETE_SELECTED,
    modalTitle: I18N_BULK_DELETE_MODAL_TITLE,
    modalBody: I18N_BULK_DELETE_BODY,
  },
  BULK_DELETE_MODAL_ID,
};
</script>
<template>
  <div class="gl-my-4 gl-p-4 gl-border-1 gl-border-solid gl-border-gray-100">
    <div class="gl-display-flex gl-align-items-center">
      <div>
        <gl-sprintf :message="$options.i18n.banner(checkedCount)">
          <template #strong="{ content }">
            <strong>{{ content }}</strong>
          </template>
        </gl-sprintf>
      </div>
      <div class="gl-ml-auto">
        <gl-button
          variant="default"
          data-testid="bulk-delete-clear-button"
          @click="handleClearSelection"
        >
          {{ $options.i18n.clearSelection }}
        </gl-button>
        <gl-button
          variant="danger"
          data-testid="bulk-delete-delete-button"
          @click="handleModalShow"
        >
          {{ $options.i18n.deleteSelected }}
        </gl-button>
      </div>
    </div>
    <gl-modal
      size="sm"
      :modal-id="$options.BULK_DELETE_MODAL_ID"
      :visible="isModalVisible"
      :title="$options.i18n.modalTitle(checkedCount)"
      :action-primary="modalActionPrimary"
      :action-cancel="modalActionCancel"
      @hide="handleModalHide"
      @primary="onConfirmDelete"
    >
      <gl-sprintf
        data-testid="bulk-delete-modal-content"
        :message="$options.i18n.modalBody(checkedCount)"
      />
    </gl-modal>
  </div>
</template>
