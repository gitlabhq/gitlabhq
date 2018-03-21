<script>
  import { mapState } from 'vuex';
  import skeletonLoadingContainer from '~/vue_shared/components/skeleton_loading_container.vue';

  export default {
    components: {
      skeletonLoadingContainer,
    },
    computed: {
      ...mapState([
        'leftPanelCollapsed',
      ]),
    },
  };
</script>

<template>
  <tr
    class="loading-file"
    aria-label="Loading files"
  >
    <td class="multi-file-table-col-name">
      <skeleton-loading-container
        :small="true"
      />
    </td>
    <template v-if="!leftPanelCollapsed">
      <td class="hidden-sm hidden-xs">
        <skeleton-loading-container
          :small="true"
        />
      </td>

      <td class="hidden-xs">
        <skeleton-loading-container
          class="animation-container-right"
          :small="true"
        />
      </td>
    </template>
  </tr>
</template>
