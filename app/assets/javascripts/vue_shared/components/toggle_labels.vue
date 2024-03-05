<script>
import { GlToggle } from '@gitlab/ui';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import isShowingLabelsQuery from '~/graphql_shared/client/is_showing_labels.query.graphql';
import setIsShowingLabelsMutation from '~/graphql_shared/client/set_is_showing_labels.mutation.graphql';

export default {
  components: {
    GlToggle,
    LocalStorageSync,
  },
  data() {
    return {
      isShowingLabels: null,
    };
  },
  apollo: {
    isShowingLabels: {
      query: isShowingLabelsQuery,
      update: (data) => data.isShowingLabels,
    },
  },
  computed: {
    trackProperty() {
      return this.isShowingLabels ? 'on' : 'off';
    },
  },
  methods: {
    setShowLabels(val) {
      this.$apollo.mutate({
        mutation: setIsShowingLabelsMutation,
        variables: {
          isShowingLabels: val,
        },
      });
    },
  },
};
</script>

<template>
  <div class="board-labels-toggle-wrapper gl-display-flex gl-align-items-center gl-md-ml-3 gl-h-7">
    <local-storage-sync
      :value="isShowingLabels"
      storage-key="gl-show-board-labels"
      @input="setShowLabels"
    />
    <gl-toggle
      :value="isShowingLabels"
      :label="__('Show labels')"
      :data-track-property="trackProperty"
      data-track-action="toggle"
      data-track-label="show_labels"
      label-position="left"
      aria-describedby="board-labels-toggle-text"
      data-testid="show-labels-toggle"
      class="gl-flex-direction-row"
      @change="setShowLabels"
    />
  </div>
</template>
