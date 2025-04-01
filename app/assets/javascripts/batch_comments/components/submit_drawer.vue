<script>
import { GlButton, GlDrawer } from '@gitlab/ui';
import { mapState, mapActions } from 'pinia';
// eslint-disable-next-line no-restricted-imports
import { mapActions as mapVuexActions } from 'vuex';
import { setUrlParams, visitUrl } from '~/lib/utils/url_utility';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import { useBatchComments } from '~/batch_comments/store';
import DraftsCount from './drafts_count.vue';
import PreviewItem from './preview_item.vue';

export default {
  components: {
    GlButton,
    GlDrawer,
    DraftsCount,
    PreviewItem,
  },
  data() {
    return {
      open: false,
    };
  },
  computed: {
    ...mapState(useBatchComments, ['sortedDrafts', 'draftsCount']),
    getDrawerHeaderHeight() {
      if (!this.open) return '0';

      return getContentWrapperHeight();
    },
  },
  methods: {
    ...mapVuexActions('diffs', ['goToFile']),
    ...mapActions(useBatchComments, ['scrollToDraft']),
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
  DRAWER_Z_INDEX,
};
</script>

<template>
  <div>
    <gl-button variant="confirm" data-testid="review-drawer-toggle" @click="open = !open">
      {{ __('Your review') }}
      <drafts-count
        v-if="draftsCount > 0"
        variant="info"
        data-testid="reviewer-drawer-drafts-count-badge"
      />
    </gl-button>
    <gl-drawer
      :header-height="getDrawerHeaderHeight"
      :z-index="$options.DRAWER_Z_INDEX"
      :open="open"
      class="merge-request-review-drawer"
      data-testid="review-drawer-toggle"
      @close="open = false"
    >
      <template #title>
        <h4 class="gl-m-0">{{ __('Submit your review') }}</h4>
      </template>
      <div>
        <h5 class="h6 gl-mb-5 gl-mt-0" data-testid="reviewer-drawer-heading">
          <template v-if="draftsCount > 0">
            {{ n__('%d pending comment', '%d pending comments', draftsCount) }}
          </template>
          <template v-else>
            {{ __('No pending comments') }}
          </template>
        </h5>
        <preview-item
          v-for="draft in sortedDrafts"
          :key="draft.id"
          :draft="draft"
          class="gl-mb-3 gl-block"
          @click="onClickDraft"
        />
      </div>
    </gl-drawer>
  </div>
</template>
