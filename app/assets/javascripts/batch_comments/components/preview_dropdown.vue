<script>
import { GlIcon, GlDisclosureDropdown, GlButton } from '@gitlab/ui';
import { mapActions, mapGetters, mapState } from 'vuex';
import { setUrlParams, visitUrl } from '~/lib/utils/url_utility';
import PreviewItem from './preview_item.vue';
import DraftsCount from './drafts_count.vue';

export default {
  components: {
    GlIcon,
    PreviewItem,
    DraftsCount,
    GlDisclosureDropdown,
    GlButton,
  },
  computed: {
    ...mapState('diffs', ['viewDiffsFileByFile']),
    ...mapGetters('batchComments', ['draftsCount', 'sortedDrafts']),
    ...mapGetters(['getNoteableData']),
    listItems() {
      return this.sortedDrafts.map((item, index) => ({
        text: item.id.toString(),
        action: () => {
          this.onClickDraft(item);
        },
        last: index === this.sortedDrafts.length - 1,
        ...item,
      }));
    },
  },
  methods: {
    ...mapActions('diffs', ['setCurrentFileHash']),
    ...mapActions('batchComments', ['scrollToDraft']),
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
  <gl-disclosure-dropdown :items="listItems" dropup data-qa-selector="review_preview_dropdown">
    <template #toggle>
      <gl-button
        >{{ __('Pending comments') }} <drafts-count variant="neutral" /><gl-icon
          class="dropdown-chevron"
          name="chevron-up"
      /></gl-button>
    </template>

    <template #header>
      <p class="gl-dropdown-header-top">
        {{ n__('%d pending comment', '%d pending comments', draftsCount) }}
      </p>
    </template>

    <template #list-item="{ item }">
      <preview-item :draft="item" :is-last="item.last" @click="onClickDraft(item)" />
    </template>
  </gl-disclosure-dropdown>
</template>
