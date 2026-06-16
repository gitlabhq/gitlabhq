<script>
import {
  GlButton,
  GlIcon,
  GlCollapse,
  GlFormCheckboxGroup,
  GlFormCheckbox,
  GlPopover,
  GlAnimatedChevronRightDownIcon,
} from '@gitlab/ui';
import { xor, union, difference } from 'lodash-es';
import { __, sprintf } from '~/locale';
import { groupPermissionsByResourceAndCategory } from '~/personal_access_tokens/utils';

export default {
  name: 'PersonalAccessTokenResourcesList',
  i18n: {
    toggleCategory: __('Toggle %{category} category'),
  },
  components: {
    GlButton,
    GlIcon,
    GlCollapse,
    GlFormCheckboxGroup,
    GlFormCheckbox,
    GlPopover,
    GlAnimatedChevronRightDownIcon,
  },
  props: {
    value: {
      type: Array,
      required: false,
      default: () => [],
    },
    permissions: {
      type: Array,
      required: false,
      default: () => [],
    },
    scope: {
      type: String,
      required: true,
      validator: (value) => ['namespace', 'user', 'instance'].includes(value),
    },
    isFiltering: {
      type: Boolean,
      required: true,
    },
  },
  emits: ['input'],
  data() {
    return {
      expanded: [],
    };
  },
  computed: {
    selected: {
      get() {
        return this.value;
      },
      set(newValue) {
        this.$emit('input', newValue);
      },
    },
    resourcesGroupedByCategory() {
      return groupPermissionsByResourceAndCategory(this.permissions);
    },
  },
  methods: {
    toggle(category) {
      this.expanded = xor(this.expanded, [category]);
    },
    isExpanded(category) {
      return this.isFiltering || this.expanded.includes(category);
    },
    categoryResourceKeys(category) {
      return category.resources.map((resource) => resource.key);
    },
    isCategoryChecked(category) {
      const keys = this.categoryResourceKeys(category);
      return keys.every((key) => this.selected.includes(key));
    },
    isCategoryIndeterminate(category) {
      const keys = this.categoryResourceKeys(category);
      const selectedCount = keys.filter((key) => this.selected.includes(key)).length;
      return selectedCount > 0 && selectedCount < keys.length;
    },
    toggleCategory(category, checked) {
      const keys = this.categoryResourceKeys(category);
      this.selected = checked ? union(this.selected, keys) : difference(this.selected, keys);
    },
    toggleCategoryLabel(category) {
      return sprintf(this.$options.i18n.toggleCategory, { category: category.name });
    },
  },
};
</script>
<template>
  <div>
    <div v-for="category in resourcesGroupedByCategory" :key="category.key" class="gl-mb-4">
      <div class="gl-flex gl-items-start">
        <gl-form-checkbox
          :checked="isCategoryChecked(category)"
          :indeterminate="isCategoryIndeterminate(category)"
          class="gl-ml-1 gl-mt-3 gl-min-w-0"
          data-testid="category-select-all"
          @change="toggleCategory(category, $event)"
        >
          <span data-testid="category-name">
            {{ category.name }}
          </span>
        </gl-form-checkbox>

        <gl-button
          category="tertiary"
          class="gl-ml-auto !gl-border-none"
          :class="{ 'gl-pointer-events-none': isFiltering }"
          :disabled="isFiltering"
          :aria-label="toggleCategoryLabel(category)"
          @click="toggle(category.key)"
        >
          <gl-animated-chevron-right-down-icon :is-on="isExpanded(category.key)" />
        </gl-button>
      </div>

      <gl-collapse :visible="isExpanded(category.key)">
        <gl-form-checkbox-group v-model="selected" class="gl-pl-4">
          <div
            v-for="resource in category.resources"
            :key="resource.key"
            class="gl-flex gl-items-center"
          >
            <gl-form-checkbox :value="resource.key" class="gl-mt-4">
              {{ resource.name }}
            </gl-form-checkbox>

            <span v-if="resource.description" class="gl-ml-3 gl-mt-2">
              <gl-icon
                :id="`${scope}-${resource.key}`"
                name="information-o"
                class="gl-cursor-pointer"
              />
              <gl-popover
                :target="`${scope}-${resource.key}`"
                triggers="focus"
                no-fade
                boundary="viewport"
              >
                {{ resource.description }}
              </gl-popover>
            </span>
          </div>
        </gl-form-checkbox-group>
      </gl-collapse>
    </div>
  </div>
</template>
