<script>
import $ from 'jquery';
import { mapActions, mapGetters, mapState } from 'vuex';
import Icon from '~/vue_shared/components/icon.vue';
import tooltip from '~/vue_shared/directives/tooltip';
import { activityBarViews } from '../constants';

export default {
  components: {
    Icon,
  },
  directives: {
    tooltip,
  },
  computed: {
    ...mapGetters(['hasChanges']),
    ...mapState(['currentActivityView']),
  },
  methods: {
    ...mapActions(['updateActivityBarView']),
    changedActivityView(e, view) {
      e.currentTarget.blur();

      this.updateActivityBarView(view);

      $(e.currentTarget).tooltip('hide');
    },
  },
  activityBarViews,
};
</script>

<template>
  <nav class="ide-activity-bar">
    <ul class="list-unstyled">
      <li>
        <button
          v-tooltip
          :class="{
            active: currentActivityView === $options.activityBarViews.edit,
          }"
          :title="s__('IDE|Edit')"
          :aria-label="s__('IDE|Edit')"
          data-container="body"
          data-placement="right"
          type="button"
          class="ide-sidebar-link js-ide-edit-mode"
          @click.prevent="changedActivityView($event, $options.activityBarViews.edit)"
        >
          <icon name="code" />
        </button>
      </li>
      <li>
        <button
          v-tooltip
          :class="{
            active: currentActivityView === $options.activityBarViews.review,
          }"
          :title="s__('IDE|Review')"
          :aria-label="s__('IDE|Review')"
          data-container="body"
          data-placement="right"
          type="button"
          class="ide-sidebar-link js-ide-review-mode"
          @click.prevent="changedActivityView($event, $options.activityBarViews.review)"
        >
          <icon name="file-modified" />
        </button>
      </li>
      <li v-show="hasChanges">
        <button
          v-tooltip
          :class="{
            active: currentActivityView === $options.activityBarViews.commit,
          }"
          :title="s__('IDE|Commit')"
          :aria-label="s__('IDE|Commit')"
          data-container="body"
          data-placement="right"
          type="button"
          class="ide-sidebar-link js-ide-commit-mode qa-commit-mode-tab"
          @click.prevent="changedActivityView($event, $options.activityBarViews.commit)"
        >
          <icon name="commit" />
        </button>
      </li>
    </ul>
  </nav>
</template>
