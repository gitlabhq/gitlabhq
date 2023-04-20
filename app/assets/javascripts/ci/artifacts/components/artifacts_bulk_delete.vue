<script>
import { GlButton, GlSprintf } from '@gitlab/ui';
import {
  I18N_BULK_DELETE_BANNER,
  I18N_BULK_DELETE_CLEAR_SELECTION,
  I18N_BULK_DELETE_DELETE_SELECTED,
} from '../constants';

export default {
  name: 'ArtifactsBulkDelete',
  components: {
    GlButton,
    GlSprintf,
  },
  props: {
    selectedArtifacts: {
      type: Array,
      required: true,
    },
  },
  computed: {
    checkedCount() {
      return this.selectedArtifacts.length || 0;
    },
  },
  i18n: {
    banner: I18N_BULK_DELETE_BANNER,
    clearSelection: I18N_BULK_DELETE_CLEAR_SELECTION,
    deleteSelected: I18N_BULK_DELETE_DELETE_SELECTED,
  },
};
</script>
<template>
  <div
    v-if="selectedArtifacts.length > 0"
    class="gl-my-4 gl-p-4 gl-border-1 gl-border-solid gl-border-gray-100"
    data-testid="bulk-delete-container"
  >
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
          @click="$emit('clearSelectedArtifacts')"
        >
          {{ $options.i18n.clearSelection }}
        </gl-button>
        <gl-button
          variant="danger"
          data-testid="bulk-delete-delete-button"
          @click="$emit('showBulkDeleteModal')"
        >
          {{ $options.i18n.deleteSelected }}
        </gl-button>
      </div>
    </div>
  </div>
</template>
