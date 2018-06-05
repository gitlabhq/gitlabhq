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
          data-container="body"
          data-placement="right"
          :href="goBackUrl"
          class="ide-sidebar-link"
          :title="s__('IDE|Go back')"
          :aria-label="s__('IDE|Go back')"
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
          data-container="body"
          data-placement="right"
          type="button"
          class="ide-sidebar-link js-ide-edit-mode"
          :class="{
            active: currentActivityView === $options.activityBarViews.edit
          }"
          @click.prevent="changedActivityView($event, $options.activityBarViews.edit)"
          :title="s__('IDE|Edit')"
          :aria-label="s__('IDE|Edit')"
        >
          <icon
            name="code"
          />
        </button>
      </li>
      <li>
        <button
          v-tooltip
          data-container="body"
          data-placement="right"
          type="button"
          class="ide-sidebar-link js-ide-review-mode"
          :class="{
            active: currentActivityView === $options.activityBarViews.review
          }"
          @click.prevent="changedActivityView($event, $options.activityBarViews.review)"
          :title="s__('IDE|Review')"
          :aria-label="s__('IDE|Review')"
        >
          <icon
            name="file-modified"
          />
        </button>
      </li>
      <li v-show="hasChanges">
        <button
          v-tooltip
          data-container="body"
          data-placement="right"
          type="button"
          class="ide-sidebar-link js-ide-commit-mode"
          :class="{
            active: currentActivityView === $options.activityBarViews.commit
          }"
          @click.prevent="changedActivityView($event, $options.activityBarViews.commit)"
          :title="s__('IDE|Commit')"
          :aria-label="s__('IDE|Commit')"
        >
          <icon
            name="commit"
          />
        </button>
      </li>
    </ul>
  </nav>
</template>
