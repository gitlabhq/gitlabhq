<script>
import {
  GlBadge,
  GlButton,
  GlFormCheckbox,
  GlIcon,
  GlLoadingIcon,
  GlTooltipDirective,
  GlTruncate,
} from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import {
  SCOPE_PICKER_ITEM_TYPE_GROUP,
  SCOPE_PICKER_ITEM_TYPE_LOAD_MORE,
  SCOPE_PICKER_ITEM_TYPES,
  SCOPE_PICKER_SELECTED_ITEM_SUFFIX,
} from './constants';

export default {
  name: 'AnalyticsDashboardScopePickerItem',
  components: {
    GlBadge,
    GlButton,
    GlFormCheckbox,
    GlIcon,
    GlLoadingIcon,
    GlTruncate,
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
    itemType: {
      type: String,
      required: true,
      validator: (value) => SCOPE_PICKER_ITEM_TYPES.includes(value),
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
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
    restricted: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  emits: ['toggle-expanded', 'load-more'],
  computed: {
    isLoadMore() {
      return this.itemType === SCOPE_PICKER_ITEM_TYPE_LOAD_MORE;
    },
    isGroup() {
      return this.itemType === SCOPE_PICKER_ITEM_TYPE_GROUP;
    },
    icon() {
      return this.isGroup ? 'folder-o' : 'doc-text';
    },
    fullPath() {
      return this.value.endsWith(SCOPE_PICKER_SELECTED_ITEM_SUFFIX)
        ? this.value.slice(0, -SCOPE_PICKER_SELECTED_ITEM_SUFFIX.length)
        : this.value;
    },
    parentLabel() {
      // Not escaped by sprintf: Vue escapes the interpolation, so escaping here as well would
      // render a group called "Sales & Marketing" as `Sales &amp; Marketing`.
      return sprintf(s__('AnalyticsDashboards|in %{name}'), { name: this.parentName }, false);
    },
    restrictedLabel() {
      return this.isGroup
        ? s__(
            "AnalyticsDashboards|This group has restricted access, so you can't select it. You can select available projects and subgroups listed below it instead.",
          )
        : s__("AnalyticsDashboards|This project has restricted access, so you can't select it.");
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
    <!-- Reserve the chevron's width so rows without one stay aligned. A disabled listbox option
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

    <!-- A disabled listbox option puts pointer-events: none on its whole content, so opt the
         button back in. The listbox option owns Enter and Space, so keep those off it. -->
    <gl-button
      v-if="isLoadMore"
      category="tertiary"
      variant="confirm"
      size="small"
      class="gl-pointer-events-auto !gl-justify-start"
      :loading="loading"
      block
      data-testid="scope-picker-load-more-button"
      @click.stop="$emit('load-more')"
      @keydown.enter.stop
      @keydown.space.stop
    >
      {{ text }}
    </gl-button>

    <template v-else>
      <!-- The listbox option handles selection and announces it, so this checkbox is presentational.
           Its label also carries an 8px bottom margin for stacked lists, which pins the content to
           the top of the item's 24px line, so cancel that. Grows so the name inside it, rather than
           the parent label beside it, is what gives way when the row runs out of room. -->
      <gl-form-checkbox
        class="scope-picker-item-checkbox gl-pointer-events-none -gl-mb-3 gl-min-w-0 gl-grow"
        :checked="selected"
        :indeterminate="indeterminate"
        :disabled="disabled"
        aria-hidden="true"
        tabindex="-1"
      >
        <span class="gl-flex gl-min-w-0 gl-items-center gl-gap-2">
          <gl-icon :name="icon" class="gl-shrink-0 gl-text-subtle" />
          <span class="gl-pointer-events-auto gl-min-w-0" @click.prevent>
            <gl-truncate :text="text" with-tooltip data-testid="scope-picker-item-name" />
          </span>
        </span>
      </gl-form-checkbox>

      <span v-if="restricted" class="gl-sr-only">{{ restrictedLabel }}</span>

      <!-- Outside the button on purpose: GlButton's loading state also marks it disabled, which
           drops its click listener, so the row could not be collapsed while its children load. -->
      <gl-loading-icon v-if="expanding" class="gl-ml-auto gl-shrink-0 gl-pl-3" />

      <!-- Keeps its full width ahead of the name, but capped at 3/8 of the row so a long
           parent cannot crowd the name out. -->
      <div v-if="restricted || parentName" class="gl-ml-auto gl-flex gl-max-w-3/8 gl-shrink-0">
        <gl-badge
          v-if="restricted"
          v-gl-tooltip.bottom.viewport
          class="gl-pointer-events-auto"
          :title="restrictedLabel"
        >
          {{ s__('AnalyticsDashboards|Restricted') }}
        </gl-badge>

        <!-- The tooltip still carries the full path. -->
        <span
          v-else
          v-gl-tooltip
          :title="fullPath"
          class="gl-min-w-0 gl-truncate gl-pl-3 gl-text-sm gl-text-subtle"
          data-testid="scope-picker-item-parent"
        >
          {{ parentLabel }}
        </span>
      </div>
    </template>
  </div>
</template>
