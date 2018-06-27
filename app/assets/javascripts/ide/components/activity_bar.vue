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
    ...mapGetters(['currentProject', 'hasChanges']),
    ...mapState(['currentActivityView']),
    goBackUrl() {
      return document.referrer || this.currentProject.web_url;
    },
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
      <li v-once>
        <a
          v-tooltip
          :href="goBackUrl"
          :title="s__('IDE|Go back')"
          :aria-label="s__('IDE|Go back')"
          data-container="body"
          data-placement="right"
          class="ide-sidebar-link"
        >
          <icon
            :size="16"
            name="go-back"
          />
        </a>
      </li>
      <li>
        <button
          v-tooltip
          :class="{
            active: currentActivityView === $options.activityBarViews.edit
          }"
          :title="s__('IDE|Edit')"
          :aria-label="s__('IDE|Edit')"
          data-container="body"
          data-placement="right"
          type="button"
          class="ide-sidebar-link js-ide-edit-mode"
          @click.prevent="changedActivityView($event, $options.activityBarViews.edit)"
        >
          <icon
            name="code"
          />
        </button>
      </li>
      <li>
        <button
          v-tooltip
          :class="{
            active: currentActivityView === $options.activityBarViews.review
          }"
          :title="s__('IDE|Review')"
          :aria-label="s__('IDE|Review')"
          data-container="body"
          data-placement="right"
          type="button"
          class="ide-sidebar-link js-ide-review-mode"
          @click.prevent="changedActivityView($event, $options.activityBarViews.review)"
        >
          <icon
            name="file-modified"
          />
        </button>
      </li>
      <li v-show="hasChanges">
        <button
          v-tooltip
          :class="{
            active: currentActivityView === $options.activityBarViews.commit
          }"
          :title="s__('IDE|Commit')"
          :aria-label="s__('IDE|Commit')"
          data-container="body"
          data-placement="right"
          type="button"
          class="ide-sidebar-link js-ide-commit-mode"
          @click.prevent="changedActivityView($event, $options.activityBarViews.commit)"
        >
          <icon
            name="commit"
          />
        </button>
      </li>
    </ul>
  </nav>
</template>
