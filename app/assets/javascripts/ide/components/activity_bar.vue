<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import Icon from '~/vue_shared/components/icon.vue';
import { activityBarViews } from '../constants';

export default {
  components: {
    Icon,
  },
  computed: {
    ...mapGetters(['currentProject']),
    ...mapState(['currentActivityView']),
    goBackUrl() {
      return document.referrer || this.currentProject.web_url;
    },
  },
  methods: {
    ...mapActions(['updateActivityBarView']),
  },
  activityBarViews,
};
</script>

<template>
  <nav class="ide-activity-bar">
    <ul class="list-unstyled">
      <li v-once>
        <a
          :href="goBackUrl"
          class="ide-sidebar-link"
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
          type="button"
          class="ide-sidebar-link js-ide-edit-mode"
          :class="{
            active: currentActivityView === $options.activityBarViews.edit
          }"
          @click.prevent="updateActivityBarView($options.activityBarViews.edit)"
          :aria-label="s__('IDE|Edit mode')"
        >
          <icon
            name="code"
          />
        </button>
      </li>
      <li>
        <button
          type="button"
          class="ide-sidebar-link js-ide-review-mode"
          :class="{
            active: currentActivityView === $options.activityBarViews.review
          }"
          @click.prevent="updateActivityBarView($options.activityBarViews.review)"
        >
          <icon
            name="file-modified"
          />
        </button>
      </li>
      <li>
        <button
          type="button"
          class="ide-sidebar-link js-ide-commit-mode"
          :class="{
            active: currentActivityView === $options.activityBarViews.commit
          }"
          @click.prevent="updateActivityBarView($options.activityBarViews.commit)"
          :aria-label="s__('IDE|Commit mode')"
        >
          <icon
            name="commit"
          />
        </button>
      </li>
    </ul>
  </nav>
</template>
