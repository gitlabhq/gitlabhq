<script>
import ProjectAvatar from '~/vue_shared/components/project_avatar.vue';
import { OVERLAY_GOTO } from '../command_palette/constants';
import SearchResultHoverLayover from './global_search_hover_overlay.vue';

export default {
  name: 'FrequentlyVisitedItem',
  i18n: {
    OVERLAY_GOTO,
  },
  components: {
    ProjectAvatar,
    SearchResultHoverLayover,
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
  <search-result-hover-layover :text-message="$options.i18n.OVERLAY_GOTO">
    <project-avatar
      :project-id="item.id"
      :project-name="item.title"
      :project-avatar-url="item.avatar"
      :size="32"
      aria-hidden="true"
    />

    <div class="gl-grow gl-truncate">
      {{ item.title }}
      <div
        v-if="item.subtitle"
        data-testid="subtitle"
        class="gl-truncate gl-text-sm gl-text-subtle"
      >
        {{ item.subtitle }}
      </div>
    </div>
  </search-result-hover-layover>
</template>
