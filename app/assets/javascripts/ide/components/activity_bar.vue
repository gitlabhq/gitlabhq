<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import Icon from '~/vue_shared/components/icon.vue';
import { ActivityBarViews } from '../constants';

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
  ActivityBarViews,
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
            active: currentActivityView === $options.ActivityBarViews.edit
          }"
          @click.prevent="updateActivityBarView($options.ActivityBarViews.edit)"
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
            active: currentActivityView === $options.ActivityBarViews.review
          }"
          @click.prevent="updateActivityBarView($options.ActivityBarViews.review)"
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
            active: currentActivityView === $options.ActivityBarViews.commit
          }"
          @click.prevent="updateActivityBarView($options.ActivityBarViews.commit)"
        >
          <icon
            name="commit"
          />
        </button>
      </li>
    </ul>
  </nav>
</template>
