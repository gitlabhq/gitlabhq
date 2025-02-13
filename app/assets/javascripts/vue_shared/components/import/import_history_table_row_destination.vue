<script>
import { GlIcon, GlLink, GlTruncate } from '@gitlab/ui';
import { n__ } from '~/locale';
import ProjectAvatar from '../project_avatar.vue';

/**
 * Formatting component for the destination details of an item in an import history table
 */
export default {
  name: 'ImportHistoryTableRowDestination',
  components: {
    GlIcon,
    GlLink,
    GlTruncate,
    ProjectAvatar,
  },
  props: {
    /**
     * Should accept the data that comes from the BulkImport API endpoint, but accepts two additional optional keys:
     * - `subgroups`: Count of subgroups
     * - `projects`: Count of projects
     */
    item: {
      type: Object,
      required: true,
    },
  },
  computed: {
    avatarProps() {
      return {
        projectName: this.item.destination_name,
        ...this.item.avatarProps,
        size: 16,
      };
    },
    subGroups() {
      return n__('%d subgroup', '%d subgroups', this.item.subgroups);
    },
    projects() {
      return n__('%d project', '%d projects', this.item.projects);
    },
  },
};
</script>

<template>
  <div data-testid="import-history-table-row-destination" class="gl-flex gl-flex-col gl-gap-3">
    <div class="gl-flex gl-gap-3">
      <project-avatar v-bind="avatarProps" class="gl-self-center" />
      <gl-link
        :href="item.full_path"
        class="gl-overflow-hidden !gl-text-default hover:gl-underline"
      >
        <gl-truncate :text="item.full_path" position="middle" with-tooltip />
      </gl-link>
    </div>
    <div v-if="item.subgroups" class="gl-flex gl-items-center gl-gap-3">
      <gl-icon name="group" /> {{ subGroups }}
    </div>
    <div v-if="item.projects" class="gl-flex gl-items-center gl-gap-3">
      <gl-icon name="project" /> {{ projects }}
    </div>
  </div>
</template>
