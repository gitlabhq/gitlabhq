<script>
import {
  GlAlert,
  GlBadge,
  GlLink,
  GlLoadingIcon,
  GlSprintf,
  GlTable,
  GlTooltip,
  GlTooltipDirective,
} from '@gitlab/ui';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { s__, sprintf } from '~/locale';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import StateActions from './states_table_actions.vue';

export default {
  components: {
    CiIcon,
    GlAlert,
    GlBadge,
    GlLink,
    GlLoadingIcon,
    GlSprintf,
    GlTable,
    GlTooltip,
    StateActions,
    TimeAgoTooltip,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
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
      return [
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
        {
          key: 'actions',
          label: this.$options.i18n.actions,
          thClass: 'gl-w-12',
          tdClass: 'gl-text-right',
        },
      ];
    },
  },
  i18n: {
    actions: s__('Terraform|Actions'),
    details: s__('Terraform|Details'),
    jobStatus: s__('Terraform|Job status'),
    locked: s__('Terraform|Locked'),
    lockedByUser: s__('Terraform|Locked by %{user} %{timeAgo}'),
    lockingState: s__('Terraform|Locking state'),
    deleting: s__('Terraform|Removed'),
    deletionInProgress: s__('Terraform|Deletion in progress'),
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
    lockedByUserText(item) {
      return sprintf(this.$options.i18n.lockedByUser, {
        user: this.lockedByUserName(item),
        timeAgo: this.timeFormatted(item.lockedAt),
      });
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
    details-td-class="!gl-p-0"
    fixed
    stacked="md"
  >
    <template #cell(name)="{ item }">
      <div
        data-testid="terraform-states-table-name"
        class="gl-align-center gl-flex gl-justify-end gl-gap-3 md:gl-justify-start"
      >
        <p class="gl-m-0 gl-text-default">
          {{ item.name }}
        </p>

        <div v-if="item.loadingLock">
          <gl-loading-icon size="sm" class="gl-inline gl-pr-1" />
          {{ loadingLockText(item) }}
        </div>

        <div v-else-if="item.loadingRemove">
          <gl-loading-icon size="sm" class="gl-inline gl-pr-1" />
          {{ $options.i18n.removing }}
        </div>

        <div
          v-else-if="item.deletedAt"
          v-gl-tooltip.right
          :title="$options.i18n.deletionInProgress"
          :data-testid="`state-badge-${item.name}`"
        >
          <gl-badge icon="remove">
            {{ $options.i18n.deleting }}
          </gl-badge>
        </div>

        <div
          v-else-if="item.lockedAt"
          v-gl-tooltip.right
          :title="lockedByUserText(item)"
          :data-testid="`state-badge-${item.name}`"
        >
          <gl-badge icon="lock">
            {{ $options.i18n.locked }}
          </gl-badge>
        </div>
      </div>
    </template>

    <template #cell(pipeline)="{ item }">
      <div
        data-testid="terraform-states-table-pipeline"
        class="gl-flex gl-items-center gl-justify-end gl-gap-3 md:gl-justify-start"
      >
        <gl-link v-if="pipelineID(item)" :href="pipelinePath(item)">
          #{{ pipelineID(item) }}
        </gl-link>

        <div v-if="pipelineDetailedStatus(item)" :id="`terraformJobStatusContainer${item.name}`">
          <ci-icon
            :id="`terraformJobStatus${item.name}`"
            :status="pipelineDetailedStatus(item)"
            show-status-text
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

    <template #cell(actions)="{ item }">
      <state-actions :state="item" :terraform-admin="terraformAdmin" />
    </template>

    <template #row-details="row">
      <gl-alert
        data-testid="terraform-states-table-error"
        variant="danger"
        @dismiss="row.toggleDetails"
      >
        <span v-for="errorMessage in row.item.errorMessages" :key="errorMessage">
          {{ errorMessage }}
        </span>
      </gl-alert>
    </template>
  </gl-table>
</template>
