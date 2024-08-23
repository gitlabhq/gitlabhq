<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';
import { isLoggedIn } from '~/lib/utils/common_utils';
import ForksButton from '~/forks/components/forks_button.vue';
import MoreActionsDropdown from '~/groups_projects/components/more_actions_dropdown.vue';
import NotificationsDropdown from '~/notifications/components/notifications_dropdown.vue';
import StarCount from '~/stars/components/star_count.vue';

export default {
  components: {
    ForksButton,
    GlButton,
    MoreActionsDropdown,
    NotificationsDropdown,
    StarCount,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: {
    adminPath: {
      default: '',
    },
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
  i18n: {
    adminButtonTooltip: __('View project in admin area'),
  },
};
</script>

<template>
  <div
    class="gl-justify-content-md-end project-repo-buttons gl-flex gl-flex-wrap gl-items-center gl-gap-3"
  >
    <gl-button
      v-if="adminPath"
      v-gl-tooltip
      :aria-label="$options.i18n.adminButtonTooltip"
      :href="adminPath"
      :title="$options.i18n.adminButtonTooltip"
      data-testid="admin-button"
      icon="admin"
    />

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
