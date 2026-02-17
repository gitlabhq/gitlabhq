<script>
import {
  GlButton,
  GlIcon,
  GlCollapse,
  GlFormCheckboxGroup,
  GlFormCheckbox,
  GlPopover,
} from '@gitlab/ui';
import { xor } from 'lodash';
import { groupPermissionsByResourceAndCategory } from '~/personal_access_tokens/utils';

export default {
  name: 'PersonalAccessTokenResourcesList',
  components: {
    GlButton,
    GlIcon,
    GlCollapse,
    GlFormCheckboxGroup,
    GlFormCheckbox,
    GlPopover,
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
      return this.expanded.includes(category);
    },
  },
};
</script>
<template>
  <gl-form-checkbox-group v-model="selected">
    <div v-for="category in resourcesGroupedByCategory" :key="category.key" class="gl-mb-4">
      <gl-button category="tertiary" class="gl-font-bold" @click="toggle(category.key)">
        <gl-icon :name="isExpanded(category.key) ? 'chevron-down' : 'chevron-right'" />
        <span>
          {{ category.name }}
        </span>
      </gl-button>

      <gl-collapse :visible="isExpanded(category.key)">
        <div
          v-for="resource in category.resources"
          :key="resource.key"
          class="gl-flex gl-items-center"
        >
          <gl-form-checkbox :value="resource.key" class="gl-ml-6 gl-mt-4">
            {{ resource.name }}
          </gl-form-checkbox>

          <span v-if="resource.description" class="gl-ml-3 gl-mt-2">
            <gl-icon :id="resource.key" name="information-o" class="gl-cursor-pointer" />
            <gl-popover :target="resource.key" triggers="focus" no-fade boundary="viewport">
              {{ resource.description }}
            </gl-popover>
          </span>
        </div>
      </gl-collapse>
    </div>
  </gl-form-checkbox-group>
</template>
