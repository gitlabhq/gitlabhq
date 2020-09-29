<script>
import $ from 'jquery';
import { mapActions, mapState } from 'vuex';
import { GlIcon } from '@gitlab/ui';
import tooltip from '~/vue_shared/directives/tooltip';
import { leftSidebarViews } from '../constants';

export default {
  components: {
    GlIcon,
  },
  directives: {
    tooltip,
  },
  computed: {
    ...mapState(['currentActivityView']),
  },
  methods: {
    ...mapActions(['updateActivityBarView']),
    changedActivityView(e, view) {
      e.currentTarget.blur();

      this.updateActivityBarView(view);

      // TODO: We must use JQuery here to interact with the Bootstrap tooltip API
      // https://gitlab.com/gitlab-org/gitlab/-/issues/217577
      $(e.currentTarget).tooltip('hide');
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
          v-tooltip
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
          v-tooltip
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
          v-tooltip
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
        </button>
      </li>
    </ul>
  </nav>
</template>
