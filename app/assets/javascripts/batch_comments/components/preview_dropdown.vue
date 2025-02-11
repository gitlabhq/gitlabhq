<script>
import { GlIcon, GlDisclosureDropdown, GlButton } from '@gitlab/ui';
import { mapState, mapActions } from 'pinia';
// eslint-disable-next-line no-restricted-imports
import {
  mapActions as mapVuexActions,
  mapGetters as mapVuexGetters,
  mapState as mapVuexState,
} from 'vuex';
import { setUrlParams, visitUrl } from '~/lib/utils/url_utility';
import { useBatchComments } from '~/batch_comments/store';
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
    ...mapVuexState('diffs', ['viewDiffsFileByFile']),
    ...mapState(useBatchComments, ['draftsCount', 'sortedDrafts']),
    ...mapVuexGetters(['getNoteableData']),
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
    ...mapVuexActions('diffs', ['goToFile']),
    ...mapActions(useBatchComments, ['scrollToDraft']),
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
        class="gl-flex gl-min-h-8 gl-items-center gl-border-b-1 gl-border-b-dropdown !gl-p-4 gl-border-b-solid"
      >
        <span class="gl-grow gl-pr-2 gl-text-sm gl-font-bold">
          {{ n__('%d pending comment', '%d pending comments', draftsCount) }}
        </span>
      </div>
    </template>

    <template #list-item="{ item }">
      <preview-item :draft="item" :is-last="item.last" />
    </template>
  </gl-disclosure-dropdown>
</template>
