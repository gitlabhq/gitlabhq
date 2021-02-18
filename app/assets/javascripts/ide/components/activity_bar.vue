<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { mapActions, mapState } from 'vuex';
import { BV_HIDE_TOOLTIP } from '~/lib/utils/constants';
import { leftSidebarViews } from '../constants';

export default {
  components: {
    GlIcon,
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
          data-qa-selector="edit_mode_tab"
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
          type="button"
          class="ide-sidebar-link js-ide-review-mode"
          @click.prevent="changedActivityView($event, $options.leftSidebarViews.review.name)"
        >
          <gl-icon name="file-modified" />
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
          data-qa-selector="commit_mode_tab"
          type="button"
          class="ide-sidebar-link js-ide-commit-mode"
          @click.prevent="changedActivityView($event, $options.leftSidebarViews.commit.name)"
        >
          <gl-icon name="commit" />
          <div v-if="stagedFiles.length > 0" class="ide-commit-badge badge badge-pill">
            {{ stagedFiles.length }}
          </div>
        </button>
      </li>
    </ul>
  </nav>
</template>
