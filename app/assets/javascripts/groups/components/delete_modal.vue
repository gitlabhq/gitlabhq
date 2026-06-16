<script>
import { GlAlert, GlSprintf } from '@gitlab/ui';
import SecretsCount from 'ee_component/delete_modal/components/delete_modal_secrets_count.vue';
import { numberToMetricPrefix } from '~/lib/utils/number_utils';
import GroupsProjectsDeleteModal from '~/groups_projects/components/delete_modal.vue';
import { RESOURCE_TYPES } from '~/groups_projects/constants';
import { InternalEvents } from '~/tracking';

export default {
  name: 'GroupDeleteModal',
  RESOURCE_TYPES,
  components: { GroupsProjectsDeleteModal, GlAlert, GlSprintf, SecretsCount },
  mixins: [InternalEvents.mixin()],
  inject: ['triggerDeleteLocation'],
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
  data() {
    return {
      showSecretsCountFetchError: false,
    };
  },
  methods: {
    numberToMetricPrefix,
    handlePrimary() {
      this.trackEvent('trigger_delete_on_group', {
        label: this.triggerDeleteLocation,
        property: String(this.markedForDeletion),
        actor: 'user',
      });

      this.$emit('primary');
    },
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
    @primary="handlePrimary"
    @change="$emit('change', $event)"
  >
    <template #alert>
      <gl-alert
        v-if="showSecretsCountFetchError"
        data-testid="secrets-count-error"
        class="gl-mb-5"
        variant="warning"
        :dismissible="false"
      >
        {{ s__('SecretsManager|Failed to fetch secrets count.') }}
      </gl-alert>
      <gl-alert
        data-testid="group-delete-modal-stats-alert"
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
          <secrets-count
            :full-path="confirmPhrase"
            :resource-type="$options.RESOURCE_TYPES.GROUP"
            @fetch-error="showSecretsCountFetchError = true"
          />
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
  </groups-projects-delete-modal>
</template>
