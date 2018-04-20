<script>
import IdeTreeList from './ide_tree_list.vue';

export default {
  components: {
    IdeTreeList,
  },
};
</script>

<template>
  <ide-tree-list
    viewer-type="diff"
    header-class="ide-review-header"
    :disable-action-dropdown="true"
  >
    <template
      slot="header"
    >
      {{ __('Review') }}
      <div class="prepend-top-5 ide-review-sub-header">
        {{ __('Lastest changed') }}
      </div>
    </template>
  </ide-tree-list>
</template>
