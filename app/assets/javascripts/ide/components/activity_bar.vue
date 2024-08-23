<script>
import { GlIcon, GlTooltipDirective, GlBadge } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapState } from 'vuex';
import { BV_HIDE_TOOLTIP } from '~/lib/utils/constants';
import { leftSidebarViews } from '../constants';

export default {
  components: {
    GlIcon,
    GlBadge,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  computed: {
    ...mapState(['currentActivityView', 'stagedFiles']),
  },
  methods: {
    ...mapActions(['updateActivityBarView']),
    changedActivityView(e, view) {
      e.currentTarget.blur();

      this.updateActivityBarView(view);

      this.$root.$emit(BV_HIDE_TOOLTIP);
    },
  },
  leftSidebarViews,
};
</script>

<template>
  <nav class="ide-activity-bar" data-testid="left-sidebar">
    <ul class="list-unstyled">
      <li>
        <button
          v-gl-tooltip.right.viewport
          :class="{
            active: currentActivityView === $options.leftSidebarViews.edit.name,
          }"
          :title="s__('IDE|Edit')"
          :aria-label="s__('IDE|Edit')"
          data-container="body"
          data-placement="right"
          data-testid="edit-mode-button"
          type="button"
          class="ide-sidebar-link js-ide-edit-mode"
          @click.prevent="changedActivityView($event, $options.leftSidebarViews.edit.name)"
        >
          <gl-icon name="code" />
        </button>
      </li>
      <li>
        <button
          v-gl-tooltip.right.viewport
          :class="{
            active: currentActivityView === $options.leftSidebarViews.review.name,
          }"
          :title="s__('IDE|Review')"
          :aria-label="s__('IDE|Review')"
          data-container="body"
          data-placement="right"
          data-testid="review-mode-button"
          type="button"
          class="ide-sidebar-link js-ide-review-mode"
          @click.prevent="changedActivityView($event, $options.leftSidebarViews.review.name)"
        >
          <gl-icon name="review-list" />
        </button>
      </li>
      <li>
        <button
          v-gl-tooltip.right.viewport
          :class="{
            active: currentActivityView === $options.leftSidebarViews.commit.name,
          }"
          :title="s__('IDE|Commit')"
          :aria-label="s__('IDE|Commit')"
          data-container="body"
          data-placement="right"
          data-testid="commit-mode-button"
          type="button"
          class="ide-sidebar-link js-ide-commit-mode"
          @click.prevent="changedActivityView($event, $options.leftSidebarViews.commit.name)"
        >
          <gl-icon name="commit" />
          <gl-badge
            v-if="stagedFiles.length"
            class="gl-absolute gl-right-3 gl-top-3 !gl-bg-gray-900 gl-px-2 gl-font-bold !gl-text-white"
          >
            {{ stagedFiles.length }}
          </gl-badge>
        </button>
      </li>
    </ul>
  </nav>
</template>
