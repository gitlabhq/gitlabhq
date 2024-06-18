<script>
import { GlIcon, GlDisclosureDropdown, GlButton } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
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
      const sortedDraftCount = this.sortedDrafts.length - 1;
      return this.sortedDrafts.map((item, index) => ({
        text: item.id.toString(),
        action: () => {
          this.onClickDraft(item);
        },
        last: index === sortedDraftCount,
        ...item,
      }));
    },
  },
  methods: {
    ...mapActions('diffs', ['goToFile']),
    ...mapActions('batchComments', ['scrollToDraft']),
    isOnLatestDiff(draft) {
      return draft.position?.head_sha === this.getNoteableData.diff_head_sha;
    },
    async onClickDraft(draft) {
      if (this.viewDiffsFileByFile) {
        await this.goToFile({ path: draft.file_path });
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
  <gl-disclosure-dropdown :items="listItems" dropup data-testid="review-preview-dropdown">
    <template #toggle>
      <gl-button>
        {{ __('Pending comments') }}
        <drafts-count variant="neutral" />
        <gl-icon class="dropdown-chevron" name="chevron-up" />
      </gl-button>
    </template>

    <template #header>
      <div
        class="gl-display-flex gl-align-items-center gl-p-4! gl-min-h-8 gl-border-b-1 gl-border-b-solid gl-border-b-gray-200"
      >
        <span class="gl-flex-grow-1 gl-font-bold gl-font-sm gl-pr-2">
          {{ n__('%d pending comment', '%d pending comments', draftsCount) }}
        </span>
      </div>
    </template>

    <template #list-item="{ item }">
      <preview-item :draft="item" :is-last="item.last" />
    </template>
  </gl-disclosure-dropdown>
</template>
