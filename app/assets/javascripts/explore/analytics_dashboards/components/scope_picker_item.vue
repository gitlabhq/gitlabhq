<script>
import { GlButton, GlFormCheckbox, GlIcon } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import { TYPENAME_GROUP, TYPENAME_PROJECT } from '~/graphql_shared/constants';

export default {
  name: 'AnalyticsDashboardScopePickerItem',
  components: {
    GlButton,
    GlFormCheckbox,
    GlIcon,
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
    nested: {
      type: Boolean,
      required: false,
      default: false,
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
    expandLabel() {
      const template = this.expanded
        ? s__('AnalyticsDashboards|Collapse %{name}')
        : s__('AnalyticsDashboards|Expand %{name}');

      return sprintf(template, { name: this.text });
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
    <!-- Reserve the chevron's width so items without one stay aligned. -->
    <span class="gl-flex gl-w-6 gl-shrink-0 gl-justify-center">
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
         the top of the item's 24px line, so cancel that. -->
    <gl-form-checkbox
      class="gl-pointer-events-none -gl-mb-3 gl-min-w-0"
      :checked="selected"
      :indeterminate="indeterminate"
      :disabled="disabled"
      aria-hidden="true"
      tabindex="-1"
    >
      <span class="gl-flex gl-items-center gl-gap-2">
        <gl-icon :name="icon" class="gl-shrink-0 gl-text-subtle" />
        <span class="gl-min-w-0 gl-truncate">{{ text }}</span>
      </span>
    </gl-form-checkbox>
  </div>
</template>
