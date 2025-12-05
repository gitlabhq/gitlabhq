<script>
import { GlAlert, GlSprintf } from '@gitlab/ui';
import HelpPageLink from '~/vue_shared/components/help_page_link/help_page_link.vue';
import { numberToMetricPrefix } from '~/lib/utils/number_utils';
import GroupsProjectsDeleteModal from '~/groups_projects/components/delete_modal.vue';
import { RESOURCE_TYPES } from '~/groups_projects/constants';

export default {
  name: 'GroupDeleteModal',
  RESOURCE_TYPES,
  components: { GroupsProjectsDeleteModal, GlAlert, GlSprintf, HelpPageLink },
  model: {
    prop: 'visible',
    event: 'change',
  },
  props: {
    visible: {
      type: Boolean,
      required: true,
    },
    confirmPhrase: {
      type: String,
      required: true,
    },
    fullName: {
      type: String,
      required: true,
    },
    confirmLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
    subgroupsCount: {
      type: Number,
      required: false,
      default: null,
    },
    projectsCount: {
      type: Number,
      required: false,
      default: null,
    },
    markedForDeletion: {
      type: Boolean,
      required: true,
    },
    permanentDeletionDate: {
      type: String,
      required: true,
    },
  },
  emits: ['primary', 'change'],
  computed: {
    hasStats() {
      return this.subgroupsCount !== null || this.projectsCount !== null;
    },
  },
  methods: {
    numberToMetricPrefix,
  },
};
</script>

<template>
  <groups-projects-delete-modal
    :resource-type="$options.RESOURCE_TYPES.GROUP"
    :visible="visible"
    :confirm-phrase="confirmPhrase"
    :full-name="fullName"
    :confirm-loading="confirmLoading"
    :marked-for-deletion="markedForDeletion"
    :permanent-deletion-date="permanentDeletionDate"
    @primary="$emit('primary')"
    @change="$emit('change', $event)"
  >
    <template #alert>
      <gl-alert
        v-if="hasStats"
        class="gl-mb-5"
        variant="danger"
        :dismissible="false"
        :title="s__('Groups|You are about to delete this group containing:')"
      >
        <ul data-testid="group-delete-modal-stats">
          <li v-if="subgroupsCount !== null">
            <gl-sprintf :message="n__('%{count} subgroup', '%{count} subgroups', subgroupsCount)">
              <template #count>{{ numberToMetricPrefix(subgroupsCount) }}</template>
            </gl-sprintf>
          </li>
          <li v-if="projectsCount !== null">
            <gl-sprintf :message="n__('%{count} project', '%{count} projects', projectsCount)">
              <template #count>{{ numberToMetricPrefix(projectsCount) }}</template>
            </gl-sprintf>
          </li>
        </ul>
        <p class="gl-mb-0">
          {{
            s__(
              'Groups|This process deletes the group, subgroups and project repositories, and all related resources.',
            )
          }}
        </p>
      </gl-alert>
    </template>
    <template #restore-help-page-link="{ content }">
      <help-page-link href="user/group/_index" anchor="restore-a-group">{{
        content
      }}</help-page-link>
    </template>
  </groups-projects-delete-modal>
</template>
