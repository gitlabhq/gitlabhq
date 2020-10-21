<script>
import { mapActions, mapGetters } from 'vuex';
import { GlDropdown, GlDropdownItem, GlIcon } from '@gitlab/ui';
import PreviewItem from './preview_item.vue';

export default {
  components: {
    GlDropdown,
    GlDropdownItem,
    GlIcon,
    PreviewItem,
  },
  computed: {
    ...mapGetters('batchComments', ['draftsCount', 'sortedDrafts']),
  },
  methods: {
    ...mapActions('batchComments', ['scrollToDraft']),
    isLast(index) {
      return index === this.sortedDrafts.length - 1;
    },
  },
};
</script>

<template>
  <gl-dropdown
    :header-text="n__('%d pending comment', '%d pending comments', draftsCount)"
    dropup
    toggle-class="qa-review-preview-toggle"
  >
    <template #button-content>
      {{ __('Pending comments') }}
      <gl-icon class="dropdown-chevron" name="chevron-up" />
    </template>
    <gl-dropdown-item
      v-for="(draft, index) in sortedDrafts"
      :key="draft.id"
      @click="scrollToDraft(draft)"
    >
      <preview-item :draft="draft" :is-last="isLast(index)" />
    </gl-dropdown-item>
  </gl-dropdown>
</template>
