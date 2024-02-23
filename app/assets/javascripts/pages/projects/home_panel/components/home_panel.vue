<script>
import { s__, sprintf } from '~/locale';
import { isLoggedIn } from '~/lib/utils/common_utils';
import ForksButton from '~/forks/components/forks_button.vue';
import MoreActionsDropdown from '~/groups_projects/components/more_actions_dropdown.vue';
import NotificationsDropdown from '~/notifications/components/notifications_dropdown.vue';
import StarCount from '~/stars/components/star_count.vue';

export default {
  components: {
    ForksButton,
    MoreActionsDropdown,
    NotificationsDropdown,
    StarCount,
  },
  inject: {
    canReadProject: {
      default: false,
    },
    isProjectEmpty: {
      default: false,
    },
    projectId: {
      default: '',
    },
  },
  data() {
    return {
      isLoggedIn: isLoggedIn(),
    };
  },
  computed: {
    canForkProject() {
      return !this.isProjectEmpty && isLoggedIn() && this.canReadProject;
    },
    copyProjectId() {
      return sprintf(s__('ProjectPage|Project ID: %{id}'), { id: this.projectId });
    },
  },
};
</script>

<template>
  <div class="gl-display-contents">
    <template v-if="isLoggedIn && canReadProject">
      <notifications-dropdown />
    </template>

    <star-count />

    <forks-button v-if="canForkProject" />

    <template v-if="canReadProject">
      <span class="gl-sr-only" itemprop="identifier" data-testid="project-id-content">
        {{ copyProjectId }}
      </span>
    </template>

    <more-actions-dropdown />
  </div>
</template>
