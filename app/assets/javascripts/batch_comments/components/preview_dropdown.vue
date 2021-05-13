<script>
import { GlDropdown, GlDropdownItem, GlIcon } from '@gitlab/ui';
import { mapActions, mapGetters, mapState } from 'vuex';
import PreviewItem from './preview_item.vue';

export default {
  components: {
    GlDropdown,
    GlDropdownItem,
    GlIcon,
    PreviewItem,
  },
  computed: {
    ...mapState('diffs', ['viewDiffsFileByFile']),
    ...mapGetters('batchComments', ['draftsCount', 'sortedDrafts']),
  },
  methods: {
    ...mapActions('diffs', ['toggleActiveFileByHash']),
    ...mapActions('batchComments', ['scrollToDraft']),
    isLast(index) {
      return index === this.sortedDrafts.length - 1;
    },
    async onClickDraft(draft) {
      if (this.viewDiffsFileByFile && draft.file_hash) {
        await this.toggleActiveFileByHash(draft.file_hash);
      }

      await this.scrollToDraft(draft);
    },
  },
};
</script>

<template>
  <gl-dropdown
    :header-text="n__('%d pending comment', '%d pending comments', draftsCount)"
    dropup
    data-qa-selector="review_preview_dropdown"
  >
    <template #button-content>
      {{ __('Pending comments') }}
      <gl-icon class="dropdown-chevron" name="chevron-up" />
    </template>
    <gl-dropdown-item
      v-for="(draft, index) in sortedDrafts"
      :key="draft.id"
      data-testid="preview-item"
      @click="onClickDraft(draft)"
    >
      <preview-item :draft="draft" :is-last="isLast(index)" />
    </gl-dropdown-item>
  </gl-dropdown>
</template>
