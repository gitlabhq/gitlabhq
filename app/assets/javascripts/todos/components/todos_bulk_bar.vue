<script>
import { GlButton, GlSprintf, GlTooltipDirective } from '@gitlab/ui';
import { TABS_INDICES } from '~/todos/constants';
import { s__ } from '~/locale';

export default {
  components: {
    GlButton,
    GlSprintf,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
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
    <div>
      <gl-button
        v-if="showSnooze"
        v-gl-tooltip
        data-testid="bulk-action-snooze"
        icon="clock"
        :title="$options.i18n.snoozeTitle"
        :aria-label="$options.i18n.snoozeTitle"
      />
      <gl-button
        v-if="showUnsnooze"
        v-gl-tooltip
        data-testid="bulk-action-unsnooze"
        icon="time-out"
        :title="$options.i18n.unsnoozeTitle"
        :aria-label="$options.i18n.unsnoozeTitle"
      />
      <gl-button
        v-if="showResolve"
        v-gl-tooltip
        data-testid="bulk-action-resolve"
        icon="check"
        :title="$options.i18n.resolveTitle"
        :aria-label="$options.i18n.resolveTitle"
      />
      <gl-button
        v-if="showRestore"
        v-gl-tooltip
        data-testid="bulk-action-restore"
        icon="redo"
        :title="$options.i18n.restoreTitle"
        :aria-label="$options.i18n.restoreTitle"
      />
    </div>
  </div>
</template>
