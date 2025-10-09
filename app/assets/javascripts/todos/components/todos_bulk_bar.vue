<script>
import { GlButton, GlSprintf, GlTooltipDirective } from '@gitlab/ui';
import { TABS_INDICES } from '~/todos/constants';
import { n__, s__ } from '~/locale';
import { bulkMutationsMixin } from './mixins/bulk_mutations';
import bulkResolveTodosMutation from './mutations/bulk_resolve_todos.mutation.graphql';
import bulkRestoreTodosMutation from './mutations/undo_mark_all_as_done.mutation.graphql';
import bulkUnsnoozeTodosMutation from './mutations/bulk_unsnooze_todos.mutation.graphql';
import bulkSnoozeTodosMutation from './mutations/bulk_snooze_todos.mutation.graphql';
import SnoozeTimePicker from './todo_snooze_until_picker.vue';

export default {
  components: {
    GlButton,
    GlSprintf,
    SnoozeTimePicker,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [bulkMutationsMixin],
  props: {
    ids: {
      type: Array,
      required: true,
    },
    tab: {
      type: Number,
      required: true,
    },
  },
  computed: {
    showResolve() {
      return this.tab === TABS_INDICES.pending || this.tab === TABS_INDICES.snoozed;
    },
    showRestore() {
      return this.tab === TABS_INDICES.done;
    },
    showSnooze() {
      return this.tab === TABS_INDICES.pending;
    },
    showUnsnooze() {
      return this.tab === TABS_INDICES.snoozed;
    },
  },
  i18n: {
    snoozeTitle: s__('Todos|Snooze selected items'),
    unsnoozeTitle: s__('Todos|Remove snooze for selected items'),
    resolveTitle: s__('Todos|Mark selected items as done'),
    restoreTitle: s__('Todos|Mark selected items as pending'),
  },
  methods: {
    async bulkResolve(ids, undoable = true) {
      this.handleBulkMutation({
        mutation: bulkResolveTodosMutation,
        variables: { todoIDs: ids },
        responseKey: 'bulkResolveTodos',
        trackingLabel: 'bulk_resolve',
        getMessage: (count) =>
          n__('Todos|Marked 1 to-do as done', 'Todos|Marked %d to-dos as done', count),
        undoMethod: undoable ? 'bulkRestore' : null,
      });
    },

    async bulkRestore(ids, undoable = true) {
      this.handleBulkMutation({
        mutation: bulkRestoreTodosMutation,
        variables: { todoIDs: ids },
        responseKey: 'undoMarkAllAsDone',
        trackingLabel: 'bulk_restore',
        getMessage: (count) => n__('Todos|Restored 1 to-do', 'Todos|Restored %d to-dos', count),
        undoMethod: undoable ? 'bulkResolve' : null,
      });
    },

    async bulkSnooze(ids, until, undoable = true) {
      this.handleBulkMutation({
        mutation: bulkSnoozeTodosMutation,
        variables: { todoIDs: ids, snoozeUntil: until },
        responseKey: 'bulkSnoozeTodos',
        trackingLabel: 'bulk_snooze',
        getMessage: (count) => n__('Todos|Snoozed 1 to-do', 'Todos|Snoozed %d to-dos', count),
        undoMethod: undoable ? 'bulkUnsnooze' : null,
      });
    },

    async bulkUnsnooze(ids) {
      this.handleBulkMutation({
        mutation: bulkUnsnoozeTodosMutation,
        variables: { todoIDs: ids },
        responseKey: 'bulkUnsnoozeTodos',
        trackingLabel: 'bulk_unsnooze',
        getMessage: (count) =>
          n__('Todos|Removed snooze from 1 to-do', 'Todos|Removed snooze from %d to-dos', count),
        undoMethod: null,
      });
    },
  },
};
</script>

<template>
  <div class="gl-flex gl-flex-grow gl-flex-row gl-items-baseline gl-justify-between gl-gap-1">
    <span data-testid="selected-count">
      <gl-sprintf :message="n__('Todos|%{count} selected', 'Todos|%{count} selected', ids.length)">
        <template #count>
          <strong>{{ ids.length }}</strong>
        </template>
      </gl-sprintf>
    </span>
    <div class="gl-flex gl-gap-3">
      <snooze-time-picker v-if="showSnooze" @snooze-until="(until) => bulkSnooze(ids, until)" />
      <gl-button
        v-if="showUnsnooze"
        v-gl-tooltip
        data-testid="bulk-action-unsnooze"
        icon="time-out"
        :title="$options.i18n.unsnoozeTitle"
        :aria-label="$options.i18n.unsnoozeTitle"
        @click="bulkUnsnooze(ids)"
      />
      <gl-button
        v-if="showResolve"
        v-gl-tooltip
        data-testid="bulk-action-resolve"
        icon="check"
        :title="$options.i18n.resolveTitle"
        :aria-label="$options.i18n.resolveTitle"
        @click="bulkResolve(ids)"
      />
      <gl-button
        v-if="showRestore"
        v-gl-tooltip
        data-testid="bulk-action-restore"
        icon="redo"
        :title="$options.i18n.restoreTitle"
        :aria-label="$options.i18n.restoreTitle"
        @click="bulkRestore(ids)"
      />
    </div>
  </div>
</template>
