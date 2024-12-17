<script>
import { GlAlert, GlButton, GlLoadingIcon, GlDrawer, GlFormCheckbox } from '@gitlab/ui';
import { humanize } from '~/lib/utils/text_utility';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { s__ } from '~/locale';
import { toggleArrayItem } from '~/lib/utils/array_utility';
import { getVisualizationCategory } from '../utils';
import { CATEGORY_SINGLE_STATS, CATEGORY_CHARTS, CATEGORY_TABLES } from '../constants';

export default {
  name: 'AvailableVisualizatiosnDrawer',
  components: {
    GlAlert,
    GlButton,
    GlLoadingIcon,
    GlDrawer,
    GlFormCheckbox,
  },
  props: {
    visualizations: {
      type: Array,
      required: true,
    },
    loading: {
      type: Boolean,
      required: true,
    },
    hasError: {
      type: Boolean,
      required: false,
      default: false,
    },
    open: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      selected: [],
    };
  },
  computed: {
    getDrawerHeaderHeight() {
      // avoid calculating this in advance because it causes layout thrashing
      // https://gitlab.com/gitlab-org/gitlab/-/issues/331172#note_1269378396
      if (!this.open) return '0';
      return getContentWrapperHeight();
    },
    addButtonDisabled() {
      return this.selected.length < 1;
    },
    categorizedVisualizations() {
      return this.visualizations.reduce(
        (categories, visualization) => {
          const category = getVisualizationCategory(visualization);
          categories[category].visualizations.push(visualization);
          return categories;
        },
        {
          [CATEGORY_SINGLE_STATS]: {
            title: s__('Analytics|Single stats'),
            visualizations: [],
          },
          [CATEGORY_TABLES]: {
            title: s__('Analytics|Tables'),
            visualizations: [],
          },
          [CATEGORY_CHARTS]: {
            title: s__('Analytics|Charts'),
            visualizations: [],
          },
        },
      );
    },
    filteredCategorizedVisualizations() {
      return Object.fromEntries(
        // eslint-disable-next-line no-unused-vars
        Object.entries(this.categorizedVisualizations).filter(([_, category]) => {
          return category.visualizations.length > 0;
        }),
      );
    },
  },
  watch: {
    open: {
      immediate: true,
      handler(opened) {
        if (opened) {
          this.focusFirstCheckbox();
        }
      },
    },
  },
  methods: {
    async focusFirstCheckbox() {
      if (Object.keys(this.filteredCategorizedVisualizations).length < 1) return;

      // Wait for checkboxes to render
      await this.$nextTick();

      this.$refs.checkbox[0].$el.querySelector('input').focus();
    },
    clickedListItem(visualization, event) {
      // Only toggle the selected value if the list item itself was clicked
      // to prevent checkbox clicks from double toggling
      if (event?.target?.tagName !== 'LI') {
        return;
      }

      this.selected = toggleArrayItem(this.selected, visualization);
    },
    getVisualizationTitle(slug) {
      return humanize(slug);
    },
    onAddClicked() {
      this.$emit('select', this.selected);

      this.selected = [];
    },
  },
  DRAWER_Z_INDEX,
};
</script>

<template>
  <gl-drawer
    :open="open"
    :header-height="getDrawerHeaderHeight"
    :z-index="$options.DRAWER_Z_INDEX"
    @close="$emit('close')"
  >
    <template #title>
      <h3 class="gl-m-0">{{ s__('Analytics|Add visualizations') }}</h3>
    </template>

    <gl-loading-icon v-if="loading" size="md" class="gl-mb-4" />

    <gl-alert
      v-else-if="hasError"
      variant="danger"
      :show-icon="false"
      :dismissible="false"
      class="gl-m-4"
    >
      {{
        s__(
          'Analytics|Something went wrong while loading available visualizations. Refresh the page to try again.',
        )
      }}
    </gl-alert>

    <div v-else>
      <div v-for="(category, key) in filteredCategorizedVisualizations" :key="key">
        <div data-testid="category-title" class="gl-mb-4 gl-font-bold gl-text-default">
          {{ category.title }}
        </div>
        <ul class="gl-mb-6 gl-list-none gl-p-0">
          <li
            v-for="(visualization, index) in category.visualizations"
            :key="index"
            :data-testid="`list-item-${visualization.slug}`"
            class="gl-border gl-mb-4 gl-flex gl-cursor-pointer gl-rounded-base gl-px-4 gl-pb-2 gl-pt-4"
            @click="clickedListItem(visualization, $event)"
          >
            <gl-form-checkbox ref="checkbox" v-model="selected" :value="visualization">
              {{ getVisualizationTitle(visualization.slug) }}
            </gl-form-checkbox>
          </li>
        </ul>
      </div>
    </div>

    <template #footer>
      <gl-button
        :disabled="addButtonDisabled"
        data-testid="add-button"
        block
        variant="confirm"
        category="secondary"
        @click="onAddClicked"
        >{{ s__('Analytics|Add to dashboard') }}</gl-button
      >
    </template>
  </gl-drawer>
</template>
