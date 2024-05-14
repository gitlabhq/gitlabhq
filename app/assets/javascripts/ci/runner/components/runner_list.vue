<script>
import { GlFormCheckbox, GlTableLite, GlTooltipDirective, GlSkeletonLoader } from '@gitlab/ui';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { s__ } from '~/locale';
import HelpPopover from '~/vue_shared/components/help_popover.vue';
import checkedRunnerIdsQuery from '../graphql/list/checked_runner_ids.query.graphql';
import { tableField } from '../utils';
import RunnerBulkDelete from './runner_bulk_delete.vue';
import RunnerBulkDeleteCheckbox from './runner_bulk_delete_checkbox.vue';
import RunnerConfigurationPopover from './runner_configuration_popover.vue';
import RunnerSummaryCell from './cells/runner_summary_cell.vue';
import RunnerStatusCell from './cells/runner_status_cell.vue';
import RunnerOwnerCell from './cells/runner_owner_cell.vue';

const defaultFields = [
  tableField({ key: 'status', label: s__('Runners|Status'), thClasses: ['gl-w-3/20'] }),
  tableField({ key: 'summary', label: s__('Runners|Runner configuration') }),
  tableField({ key: 'owner', label: s__('Runners|Owner'), thClasses: ['gl-w-4/20'] }),
  tableField({ key: 'actions', label: '', thClasses: ['gl-w-3/20'] }),
];

export default {
  components: {
    GlFormCheckbox,
    GlTableLite,
    GlSkeletonLoader,
    HelpPopover,
    RunnerBulkDelete,
    RunnerBulkDeleteCheckbox,
    RunnerConfigurationPopover,
    RunnerSummaryCell,
    RunnerStatusCell,
    RunnerOwnerCell,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  apollo: {
    checkedRunnerIds: {
      query: checkedRunnerIdsQuery,
      skip() {
        return !this.checkable;
      },
    },
  },
  inject: ['localMutations'],
  props: {
    checkable: {
      type: Boolean,
      required: false,
      default: false,
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
    runners: {
      type: Array,
      required: true,
    },
  },
  emits: ['deleted'],
  data() {
    return { checkedRunnerIds: [] };
  },
  computed: {
    tableClass() {
      // <gl-table-lite> does not provide a busy state, add
      // simple support for it.
      // See http://bootstrap-vue.org/docs/components/table#table-busy-state
      return {
        'gl-opacity-6': this.loading,
      };
    },
    fields() {
      const fields = defaultFields;

      if (this.checkable) {
        const checkboxField = tableField({
          key: 'checkbox',
          label: s__('Runners|Checkbox'),
          thClasses: ['gl-w-9'],
          tdClass: ['gl-text-center'],
        });
        return [checkboxField, ...fields];
      }
      return fields;
    },
  },
  methods: {
    canDelete(runner) {
      return runner.userPermissions?.deleteRunner;
    },
    onDeleted(event) {
      this.$emit('deleted', event);
    },
    runnerTrAttr(runner) {
      if (runner) {
        return {
          'data-testid': `runner-row-${getIdFromGraphQLId(runner.id)}`,
        };
      }
      return {};
    },
    onCheckboxChange(runner, isChecked) {
      this.localMutations.setRunnerChecked({
        runner,
        isChecked,
      });
    },
    isChecked(runner) {
      return this.checkedRunnerIds.includes(runner.id);
    },
  },
};
</script>
<template>
  <div>
    <runner-bulk-delete v-if="checkable" :runners="runners" @deleted="onDeleted" />
    <gl-table-lite
      :aria-busy="loading"
      :class="tableClass"
      :items="runners"
      :fields="fields"
      :tbody-tr-attr="runnerTrAttr"
      data-testid="runner-list"
      stacked="md"
      primary-key="id"
      fixed
    >
      <template #head(checkbox)>
        <runner-bulk-delete-checkbox :runners="runners" />
      </template>

      <template #cell(checkbox)="{ item }">
        <gl-form-checkbox
          v-if="canDelete(item)"
          :checked="isChecked(item)"
          @change="onCheckboxChange(item, $event)"
        />
      </template>

      <template #head(status)="{ label }">
        {{ label }}
      </template>

      <template #cell(status)="{ item }">
        <runner-status-cell :runner="item">
          <template #runner-job-status-badge="{ runner }">
            <slot name="runner-job-status-badge" :runner="runner"></slot>
          </template>
        </runner-status-cell>
      </template>

      <template #head(summary)="{ label }">
        {{ label }}
        <runner-configuration-popover />
      </template>

      <template #cell(summary)="{ item }">
        <runner-summary-cell :runner="item">
          <template #runner-name="{ runner }">
            <slot name="runner-name" :runner="runner"></slot>
          </template>
        </runner-summary-cell>
      </template>

      <template #head(owner)="{ label }">
        {{ label }}
        <help-popover>
          {{
            s__(
              'Runners|The project, group or instance where the runner was registered. Instance runners are always owned by Administrator.',
            )
          }}
        </help-popover>
      </template>

      <template #cell(owner)="{ item }">
        <runner-owner-cell :runner="item" />
      </template>

      <template #cell(actions)="{ item }">
        <slot name="runner-actions-cell" :runner="item"></slot>
      </template>
    </gl-table-lite>

    <template v-if="!runners.length && loading">
      <gl-skeleton-loader v-for="i in 4" :key="i" />
    </template>
  </div>
</template>
