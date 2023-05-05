<script>
import { createAlert } from '~/alert';
import { DynamicScroller, DynamicScrollerItem } from 'vendor/vue-virtual-scroller';
import getJobArtifactsQuery from '../graphql/queries/get_job_artifacts.query.graphql';
import destroyArtifactMutation from '../graphql/mutations/destroy_artifact.mutation.graphql';
import { removeArtifactFromStore } from '../graphql/cache_update';
import {
  I18N_DESTROY_ERROR,
  ARTIFACT_ROW_HEIGHT,
  ARTIFACTS_SHOWN_WITHOUT_SCROLLING,
} from '../constants';
import ArtifactRow from './artifact_row.vue';
import ArtifactDeleteModal from './artifact_delete_modal.vue';

export default {
  name: 'ArtifactsTableRowDetails',
  components: {
    DynamicScroller,
    DynamicScrollerItem,
    ArtifactRow,
    ArtifactDeleteModal,
  },
  props: {
    artifacts: {
      type: Object,
      required: true,
    },
    selectedArtifacts: {
      type: Array,
      required: true,
    },
    queryVariables: {
      type: Object,
      required: true,
    },
    isSelectedArtifactsLimitReached: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      isModalVisible: false,
      deleteInProgress: false,
      deletingArtifactId: null,
      deletingArtifactName: '',
    };
  },
  computed: {
    scrollContainerStyle() {
      /*
       limit the height of the expanded artifacts container to a number of artifacts
       if a job has more artifacts than ARTIFACTS_SHOWN_WITHOUT_SCROLLING, scroll to see the rest
       add one pixel to row height to account for borders
      */
      return { maxHeight: `${ARTIFACTS_SHOWN_WITHOUT_SCROLLING * (ARTIFACT_ROW_HEIGHT + 1)}px` };
    },
  },
  methods: {
    isLastRow(index) {
      return index === this.artifacts.nodes.length - 1;
    },
    isSelected(item) {
      return this.selectedArtifacts.includes(item.id);
    },
    showModal(item) {
      this.deletingArtifactId = item.id;
      this.deletingArtifactName = item.name;
      this.isModalVisible = true;
    },
    hideModal() {
      this.isModalVisible = false;
    },
    clearModal() {
      this.deletingArtifactId = null;
      this.deletingArtifactName = '';
    },
    destroyArtifact() {
      const id = this.deletingArtifactId;
      this.deleteInProgress = true;

      this.$apollo
        .mutate({
          mutation: destroyArtifactMutation,
          variables: { id },
          update: (store) => {
            removeArtifactFromStore(store, id, getJobArtifactsQuery, this.queryVariables);
          },
        })
        .catch(() => {
          createAlert({
            message: I18N_DESTROY_ERROR,
          });
          this.$emit('refetch');
        })
        .finally(() => {
          this.deleteInProgress = false;
          this.clearModal();
        });
    },
  },
  ARTIFACT_ROW_HEIGHT,
};
</script>
<template>
  <div :style="scrollContainerStyle" class="gl-overflow-auto">
    <dynamic-scroller :items="artifacts.nodes" :min-item-size="$options.ARTIFACT_ROW_HEIGHT">
      <template #default="{ item, index, active }">
        <dynamic-scroller-item :item="item" :active="active" :class="{ active }">
          <artifact-row
            :artifact="item"
            :is-selected="isSelected(item)"
            :is-last-row="isLastRow(index)"
            :is-selected-artifacts-limit-reached="isSelectedArtifactsLimitReached"
            v-on="$listeners"
            @delete="showModal(item)"
          />
        </dynamic-scroller-item>
      </template>
    </dynamic-scroller>
    <artifact-delete-modal
      :artifact-name="deletingArtifactName"
      :visible="isModalVisible"
      :delete-in-progress="deleteInProgress"
      @primary="destroyArtifact"
      @cancel="hideModal"
      @close="hideModal"
      @hide="hideModal"
      @hidden="clearModal"
    />
  </div>
</template>
