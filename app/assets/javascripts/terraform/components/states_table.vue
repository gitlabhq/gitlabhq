<script>
import {
  GlAlert,
  GlBadge,
  GlIcon,
  GlLink,
  GlLoadingIcon,
  GlSprintf,
  GlTable,
  GlTooltip,
} from '@gitlab/ui';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { s__ } from '~/locale';
import CiBadge from '~/vue_shared/components/ci_badge_link.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import StateActions from './states_table_actions.vue';

export default {
  components: {
    CiBadge,
    GlAlert,
    GlBadge,
    GlIcon,
    GlLink,
    GlLoadingIcon,
    GlSprintf,
    GlTable,
    GlTooltip,
    StateActions,
    TimeAgoTooltip,
  },
  mixins: [timeagoMixin],
  props: {
    states: {
      required: true,
      type: Array,
    },
    terraformAdmin: {
      required: false,
      type: Boolean,
      default: false,
    },
  },
  computed: {
    fields() {
      const columns = [
        {
          key: 'name',
          label: this.$options.i18n.name,
        },
        {
          key: 'pipeline',
          label: this.$options.i18n.pipeline,
        },
        {
          key: 'updated',
          label: this.$options.i18n.details,
        },
      ];

      if (this.terraformAdmin) {
        columns.push({
          key: 'actions',
          label: this.$options.i18n.actions,
          thClass: 'gl-w-12',
          tdClass: 'gl-text-right',
        });
      }

      return columns;
    },
  },
  i18n: {
    actions: s__('Terraform|Actions'),
    details: s__('Terraform|Details'),
    jobStatus: s__('Terraform|Job status'),
    locked: s__('Terraform|Locked'),
    lockedByUser: s__('Terraform|Locked by %{user} %{timeAgo}'),
    lockingState: s__('Terraform|Locking state'),
    name: s__('Terraform|Name'),
    pipeline: s__('Terraform|Pipeline'),
    removing: s__('Terraform|Removing'),
    unknownUser: s__('Terraform|Unknown User'),
    unlockingState: s__('Terraform|Unlocking state'),
    updatedUser: s__('Terraform|%{user} updated %{timeAgo}'),
  },
  methods: {
    createdByUserName(item) {
      return item.latestVersion?.createdByUser?.name;
    },
    loadingLockText(item) {
      return item.lockedAt ? this.$options.i18n.unlockingState : this.$options.i18n.lockingState;
    },
    lockedByUserName(item) {
      return item.lockedByUser?.name || this.$options.i18n.unknownUser;
    },
    pipelineDetailedStatus(item) {
      return item.latestVersion?.job?.detailedStatus;
    },
    pipelineID(item) {
      let id = item.latestVersion?.job?.pipeline?.id;

      if (id) {
        id = getIdFromGraphQLId(id);
      }

      return id;
    },
    pipelinePath(item) {
      return item.latestVersion?.job?.pipeline?.path;
    },
    updatedTime(item) {
      return item.latestVersion?.updatedAt || item.updatedAt;
    },
  },
};
</script>

<template>
  <gl-table
    :items="states"
    :fields="fields"
    data-testid="terraform-states-table"
    details-td-class="gl-p-0!"
    fixed
    stacked="md"
  >
    <template #cell(name)="{ item }">
      <div
        class="gl-display-flex align-items-center gl-justify-content-end gl-justify-content-md-start"
        data-testid="terraform-states-table-name"
      >
        <p class="gl-font-weight-bold gl-m-0 gl-text-gray-900">
          {{ item.name }}
        </p>

        <div v-if="item.loadingLock" class="gl-mx-3">
          <p class="gl-display-flex gl-justify-content-start gl-align-items-baseline gl-m-0">
            <gl-loading-icon size="sm" class="gl-pr-1" />
            {{ loadingLockText(item) }}
          </p>
        </div>

        <div v-else-if="item.loadingRemove" class="gl-mx-3">
          <p
            class="gl-display-flex gl-justify-content-start gl-align-items-baseline gl-m-0 gl-text-red-500"
          >
            <gl-loading-icon size="sm" class="gl-pr-1" />
            {{ $options.i18n.removing }}
          </p>
        </div>

        <div
          v-else-if="item.lockedAt"
          :id="`terraformLockedBadgeContainer${item.name}`"
          class="gl-mx-3"
        >
          <gl-badge :id="`terraformLockedBadge${item.name}`">
            <gl-icon name="lock" />
            {{ $options.i18n.locked }}
          </gl-badge>

          <gl-tooltip
            :container="`terraformLockedBadgeContainer${item.name}`"
            :target="`terraformLockedBadge${item.name}`"
            placement="right"
          >
            <gl-sprintf :message="$options.i18n.lockedByUser">
              <template #user>
                {{ lockedByUserName(item) }}
              </template>

              <template #timeAgo>
                {{ timeFormatted(item.lockedAt) }}
              </template>
            </gl-sprintf>
          </gl-tooltip>
        </div>
      </div>
    </template>

    <template #cell(pipeline)="{ item }">
      <div data-testid="terraform-states-table-pipeline" class="gl-min-h-7">
        <gl-link v-if="pipelineID(item)" :href="pipelinePath(item)">
          #{{ pipelineID(item) }}
        </gl-link>

        <div
          v-if="pipelineDetailedStatus(item)"
          :id="`terraformJobStatusContainer${item.name}`"
          class="gl-my-2"
        >
          <ci-badge
            :id="`terraformJobStatus${item.name}`"
            :status="pipelineDetailedStatus(item)"
            class="gl-py-1"
          />

          <gl-tooltip
            :container="`terraformJobStatusContainer${item.name}`"
            :target="`terraformJobStatus${item.name}`"
            placement="right"
          >
            {{ $options.i18n.jobStatus }}
          </gl-tooltip>
        </div>
      </div>
    </template>

    <template #cell(updated)="{ item }">
      <p class="gl-m-0" data-testid="terraform-states-table-updated">
        <gl-sprintf :message="$options.i18n.updatedUser">
          <template #user>
            <span v-if="item.latestVersion">
              {{ createdByUserName(item) }}
            </span>
          </template>

          <template #timeAgo>
            <time-ago-tooltip :time="updatedTime(item)" />
          </template>
        </gl-sprintf>
      </p>
    </template>

    <template v-if="terraformAdmin" #cell(actions)="{ item }">
      <state-actions :state="item" />
    </template>

    <template #row-details="row">
      <gl-alert
        data-testid="terraform-states-table-error"
        variant="danger"
        @dismiss="row.toggleDetails"
      >
        <span
          v-for="errorMessage in row.item.errorMessages"
          :key="errorMessage"
          class="gl-display-flex gl-justify-content-start"
        >
          {{ errorMessage }}
        </span>
      </gl-alert>
    </template>
  </gl-table>
</template>
