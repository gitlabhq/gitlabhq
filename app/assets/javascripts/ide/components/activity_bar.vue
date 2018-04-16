<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import Icon from '~/vue_shared/components/icon.vue';
import ExternalLinks from './ide_external_links.vue';
import { ActivityBarViews } from '../stores/state';

export default {
  components: {
    Icon,
    ExternalLinks,
  },
  computed: {
    ...mapGetters(['currentProject']),
    ...mapState(['currentActivityView']),
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
      <li>
        <external-links
          class="ide-activity-bar-link"
          :project-url="currentProject.web_url"
        />
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
