<script>
import { GlDropdown, GlDropdownItem, GlIcon } from '@gitlab/ui';
import { mapActions, mapGetters, mapState } from 'vuex';
import { setUrlParams, visitUrl } from '~/lib/utils/url_utility';
import PreviewItem from './preview_item.vue';
import DraftsCount from './drafts_count.vue';

export default {
  components: {
    GlDropdown,
    GlDropdownItem,
    GlIcon,
    PreviewItem,
    DraftsCount,
  },
  computed: {
    ...mapState('diffs', ['viewDiffsFileByFile']),
    ...mapGetters('batchComments', ['draftsCount', 'sortedDrafts']),
    ...mapGetters(['getNoteableData']),
  },
  methods: {
    ...mapActions('diffs', ['setCurrentFileHash']),
    ...mapActions('batchComments', ['scrollToDraft']),
    isLast(index) {
      return index === this.sortedDrafts.length - 1;
    },
    isOnLatestDiff(draft) {
      return draft.position?.head_sha === this.getNoteableData.diff_head_sha;
    },
    async onClickDraft(draft) {
      if (this.viewDiffsFileByFile && draft.file_hash) {
        await this.setCurrentFileHash(draft.file_hash);
      }

      if (draft.position && !this.isOnLatestDiff(draft)) {
        const url = new URL(setUrlParams({ commit_id: draft.position.head_sha }));
        url.hash = `note_${draft.id}`;
        visitUrl(url.toString());
      } else {
        await this.scrollToDraft(draft);
      }
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
      <drafts-count variant="neutral" />
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
