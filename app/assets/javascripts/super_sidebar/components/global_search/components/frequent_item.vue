<script>
import ProjectAvatar from '~/vue_shared/components/project_avatar.vue';
import { OVERLAY_GOTO } from '../command_palette/constants';
import SearchResultFocusLayover from './global_search_focus_overlay.vue';

export default {
  name: 'FrequentlyVisitedItem',
  i18n: {
    OVERLAY_GOTO,
  },
  components: {
    ProjectAvatar,
    SearchResultFocusLayover,
  },
  props: {
    item: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <search-result-focus-layover :text-message="$options.i18n.OVERLAY_GOTO">
    <project-avatar
      :project-id="item.id"
      :project-name="item.title"
      :project-avatar-url="item.avatar"
      :size="16"
      aria-hidden="true"
    />

    <div class="gl-flex gl-flex-row gl-items-center gl-gap-2 gl-truncate">
      <span class="gl-truncate"> {{ item.title }} </span>
      <span class="gl-text-subtle" aria-hidden="true">·</span>
      <div
        v-if="item.subtitle"
        data-testid="subtitle"
        class="gl-truncate gl-text-sm gl-text-subtle"
      >
        {{ item.subtitle }}
      </div>
    </div>
  </search-result-focus-layover>
</template>
