<script>
import { GlButton, GlFormCheckbox, GlIcon, GlLoadingIcon, GlTooltipDirective } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import { TYPENAME_GROUP, TYPENAME_PROJECT } from '~/graphql_shared/constants';

export default {
  name: 'AnalyticsDashboardScopePickerItem',
  components: {
    GlButton,
    GlFormCheckbox,
    GlIcon,
    GlLoadingIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    value: {
      type: String,
      required: true,
    },
    text: {
      type: String,
      required: true,
    },
    namespaceType: {
      type: String,
      required: true,
      validator: (value) => [TYPENAME_GROUP, TYPENAME_PROJECT].includes(value),
    },
    selected: {
      type: Boolean,
      required: false,
      default: false,
    },
    indeterminate: {
      type: Boolean,
      required: false,
      default: false,
    },
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    expandable: {
      type: Boolean,
      required: false,
      default: false,
    },
    expanded: {
      type: Boolean,
      required: false,
      default: false,
    },
    expanding: {
      type: Boolean,
      required: false,
      default: false,
    },
    nested: {
      type: Boolean,
      required: false,
      default: false,
    },
    // Names the group a flattened project actually sits in, when that is not the row above it.
    parentName: {
      type: String,
      required: false,
      default: null,
    },
  },
  emits: ['toggle-expanded'],
  computed: {
    isGroup() {
      return this.namespaceType === TYPENAME_GROUP;
    },
    icon() {
      return this.isGroup ? 'folder-o' : 'doc-text';
    },
    parentLabel() {
      // Not escaped by sprintf: Vue escapes the interpolation, so escaping here as well would
      // render a group called "Sales & Marketing" as `Sales &amp; Marketing`.
      return sprintf(s__('AnalyticsDashboards|in %{name}'), { name: this.parentName }, false);
    },
    expandLabel() {
      const template = this.expanded
        ? s__('AnalyticsDashboards|Collapse %{name}')
        : s__('AnalyticsDashboards|Expand %{name}');

      return sprintf(template, { name: this.text }, false);
    },
  },
};
</script>

<template>
  <div
    class="-gl-m-2 gl-flex gl-items-center gl-gap-2"
    :class="{ 'gl-pl-5': nested }"
    :data-testid="`scope-picker-item-${value}`"
  >
    <!-- Reserve the chevron's width so items without one stay aligned. A disabled listbox option
         puts pointer-events: none on its whole content, so opt the chevron back in: a row locked
         by a selected ancestor should still be browsable. -->
    <span class="gl-pointer-events-auto gl-flex gl-w-6 gl-shrink-0 gl-justify-center">
      <!-- The listbox option owns Enter and Space, so keep those off the expand button. -->
      <gl-button
        v-if="expandable"
        category="tertiary"
        size="small"
        :icon="expanded ? 'chevron-down' : 'chevron-right'"
        :aria-label="expandLabel"
        :aria-expanded="String(expanded)"
        @click.stop="$emit('toggle-expanded')"
        @keydown.enter.stop
        @keydown.space.stop
      />
    </span>

    <!-- The listbox option handles selection and announces it, so this checkbox is presentational.
         Its label also carries an 8px bottom margin for stacked lists, which pins the content to
         the top of the item's 24px line, so cancel that. Grows so the name inside it, rather than
         the parent label beside it, is what gives way when the row runs out of room. -->
    <gl-form-checkbox
      class="gl-pointer-events-none -gl-mb-3 gl-min-w-0 gl-grow"
      :checked="selected"
      :indeterminate="indeterminate"
      :disabled="disabled"
      aria-hidden="true"
      tabindex="-1"
    >
      <span class="gl-flex gl-min-w-0 gl-items-center gl-gap-2">
        <gl-icon :name="icon" class="gl-shrink-0 gl-text-subtle" />
        <span class="gl-min-w-0 gl-truncate" data-testid="scope-picker-item-name">{{ text }}</span>
      </span>
    </gl-form-checkbox>

    <!-- Outside the button on purpose: GlButton's loading state also marks it disabled, which
         drops its click listener, so the row could not be collapsed while its children load. -->
    <gl-loading-icon v-if="expanding" class="gl-ml-auto gl-shrink-0 gl-pl-3" />

    <!-- Allowed to shrink and truncate rather than crowding out the name it is qualifying, and
         capped so a long parent cannot take the row. The tooltip still carries the full path. -->
    <span
      v-if="parentName"
      v-gl-tooltip
      :title="value"
      class="gl-ml-auto gl-min-w-0 gl-max-w-1/2 gl-truncate gl-pl-3 gl-text-sm gl-text-subtle"
      data-testid="scope-picker-item-parent"
    >
      {{ parentLabel }}
    </span>
  </div>
</template>
