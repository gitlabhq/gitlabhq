<script>
import { GlDropdownSectionHeader, GlDropdownItem, GlBadge, GlIcon } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  name: 'RefResultsSection',
  components: {
    GlDropdownSectionHeader,
    GlDropdownItem,
    GlBadge,
    GlIcon,
  },
  props: {
    showHeader: {
      type: Boolean,
      required: false,
      default: true,
    },

    sectionTitle: {
      type: String,
      required: true,
    },

    totalCount: {
      type: Number,
      required: true,
    },

    /**
     * An array of object that have the following properties:
     *
     * - name (String, required): The name of the ref that will be displayed
     * - value (String, optional): The value that will be selected when the ref
     *   is selected. If not provided, `name` will be used as the value.
     *   For example, commits use the short SHA for `name`
     *   and long SHA for `value`.
     * - subtitle (String, optional): Text to render underneath the name.
     *   For example, used to render the commit's title underneath its SHA.
     * - default (Boolean, optional): Whether or not to render a "default"
     *   indicator next to the item. Used to indicate
     *   the project's default branch.
     *
     */
    items: {
      type: Array,
      required: true,
      validator: (items) => Array.isArray(items) && items.every((item) => item.name),
    },

    /**
     * The currently selected ref.
     * Used to render a check mark by the selected item.
     * */
    selectedRef: {
      type: String,
      required: false,
      default: '',
    },

    /**
     * An error object that indicates that an error
     * occurred while fetching items for this section
     */
    error: {
      type: Error,
      required: false,
      default: null,
    },

    /** The message to display if an error occurs */
    errorMessage: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    totalCountText() {
      return this.totalCount > 999 ? s__('TotalRefCountIndicator|1000+') : `${this.totalCount}`;
    },
  },
  methods: {
    showCheck(item) {
      return item.name === this.selectedRef || item.value === this.selectedRef;
    },
  },
};
</script>

<template>
  <div>
    <gl-dropdown-section-header v-if="showHeader">
      <div class="gl-display-flex align-items-center" data-testid="section-header">
        <span class="gl-mr-2 gl-mb-1">{{ sectionTitle }}</span>
        <gl-badge variant="neutral">{{ totalCountText }}</gl-badge>
      </div>
    </gl-dropdown-section-header>
    <template v-if="error">
      <div class="gl-display-flex align-items-start text-danger gl-ml-4 gl-mr-4 gl-mb-3">
        <gl-icon name="error" class="gl-mr-2 gl-mt-2 gl-flex-shrink-0" />
        <span>{{ errorMessage }}</span>
      </div>
    </template>
    <template v-else>
      <gl-dropdown-item
        v-for="item in items"
        :key="item.name"
        @click="$emit('selected', item.value || item.name)"
      >
        <div class="gl-display-flex align-items-start">
          <gl-icon
            name="mobile-issue-close"
            class="gl-mr-2 gl-flex-shrink-0"
            :class="{ 'gl-visibility-hidden': !showCheck(item) }"
          />

          <div class="gl-flex-grow-1 gl-display-flex gl-flex-direction-column">
            <span class="gl-font-monospace">{{ item.name }}</span>
            <span class="gl-text-gray-400">{{ item.subtitle }}</span>
          </div>

          <gl-badge v-if="item.default" size="sm" variant="info">{{
            s__('DefaultBranchLabel|default')
          }}</gl-badge>
        </div>
      </gl-dropdown-item>
    </template>
  </div>
</template>
