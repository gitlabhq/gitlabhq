<script>
import { createAlert } from '~/flash';
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

export default {
  name: 'ArtifactsTableRowDetails',
  components: {
    DynamicScroller,
    DynamicScrollerItem,
    ArtifactRow,
  },
  props: {
    artifacts: {
      type: Object,
      required: true,
    },
    queryVariables: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      deletingArtifactId: null,
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
    destroyArtifact(id) {
      this.deletingArtifactId = id;
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
          this.deletingArtifactId = null;
        });
    },
  },
  ARTIFACT_ROW_HEIGHT,
};
</script>
<template>
  <div :style="scrollContainerStyle">
    <dynamic-scroller :items="artifacts.nodes" :min-item-size="$options.ARTIFACT_ROW_HEIGHT">
      <template #default="{ item, index, active }">
        <dynamic-scroller-item :item="item" :active="active" :class="{ active }">
          <artifact-row
            :artifact="item"
            :is-last-row="isLastRow(index)"
            :is-loading="item.id === deletingArtifactId"
            @delete="destroyArtifact(item.id)"
          />
        </dynamic-scroller-item>
      </template>
    </dynamic-scroller>
  </div>
</template>
