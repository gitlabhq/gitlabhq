<script>
import { GlButton, GlSprintf, GlAlert } from '@gitlab/ui';
import {
  I18N_BULK_DELETE_BANNER,
  I18N_BULK_DELETE_CLEAR_SELECTION,
  I18N_BULK_DELETE_DELETE_SELECTED,
  I18N_BULK_DELETE_MAX_SELECTED,
} from '../constants';

export default {
  name: 'ArtifactsBulkDelete',
  components: {
    GlButton,
    GlSprintf,
    GlAlert,
  },
  props: {
    selectedArtifacts: {
      type: Array,
      required: true,
    },
    isSelectedArtifactsLimitReached: {
      type: Boolean,
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
    maxSelected: I18N_BULK_DELETE_MAX_SELECTED,
    clearSelection: I18N_BULK_DELETE_CLEAR_SELECTION,
    deleteSelected: I18N_BULK_DELETE_DELETE_SELECTED,
  },
};
</script>
<template>
  <div>
    <gl-alert v-if="isSelectedArtifactsLimitReached" variant="warning" :dismissible="false">
      {{ $options.i18n.maxSelected }}
    </gl-alert>

    <div
      v-if="selectedArtifacts.length > 0"
      class="gl-my-4 gl-border-1 gl-border-solid gl-border-default gl-p-4"
      data-testid="bulk-delete-container"
    >
      <div class="gl-flex gl-items-center">
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
  </div>
</template>
