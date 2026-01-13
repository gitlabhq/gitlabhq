<script>
import { GlButton, GlIcon, GlCollapse, GlFormCheckboxGroup, GlFormCheckbox } from '@gitlab/ui';
import { uniq, groupBy, map, mapValues, xor } from 'lodash';
import { __ } from '~/locale';

export default {
  name: 'PersonalAccessTokenResourcesList',
  components: {
    GlButton,
    GlIcon,
    GlCollapse,
    GlFormCheckboxGroup,
    GlFormCheckbox,
  },
  props: {
    permissions: {
      type: Array,
      required: false,
      default: () => [],
    },
    value: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  emits: ['input', 'change'],
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
    groupedItems() {
      return mapValues(groupBy(this.permissions, 'category'), (resources) =>
        uniq(map(resources, 'resource')),
      );
    },
  },
  methods: {
    toggle(category) {
      this.expanded = xor(this.expanded, [category]);
    },
    isExpanded(category) {
      return this.expanded.includes(category);
    },
    formatCategoryName(category) {
      // special case
      if (category === 'ci_cd') return this.$options.i18n.cicd;

      return this.removeUnderscore(category);
    },
    removeUnderscore(string) {
      return string.replace(/_/g, ' ');
    },
  },
  i18n: {
    cicd: __('CI/CD'),
  },
};
</script>
<template>
  <gl-form-checkbox-group v-model="selected">
    <div v-for="(resources, category) in groupedItems" :key="category" class="gl-mb-4">
      <gl-button category="tertiary" class="gl-font-bold" @click="toggle(category)">
        <gl-icon :name="isExpanded(category) ? 'chevron-down' : 'chevron-right'" />
        <span class="gl-capitalize">{{ formatCategoryName(category) }}</span>
      </gl-button>

      <gl-collapse :visible="isExpanded(category)">
        <div v-for="(resource, index) in resources" :key="index" class="gl-flex gl-items-center">
          <gl-form-checkbox
            :value="resource"
            class="gl-ml-6 gl-mt-4 gl-capitalize"
            @change="$emit('change', resource)"
          >
            {{ removeUnderscore(resource) }}
          </gl-form-checkbox>
        </div>
      </gl-collapse>
    </div>
  </gl-form-checkbox-group>
</template>
