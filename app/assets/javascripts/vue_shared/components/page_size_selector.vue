<script>
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';

export const PAGE_SIZES = [20, 50, 100];

export default {
  components: { GlDropdown, GlDropdownItem },
  props: {
    value: {
      type: Number,
      required: true,
    },
  },
  methods: {
    emitInput(pageSize) {
      this.$emit('input', pageSize);
    },
    getPageSizeText(pageSize) {
      return sprintf(s__('SecurityReports|Show %{pageSize} items'), { pageSize });
    },
  },
  PAGE_SIZES,
};
</script>

<template>
  <gl-dropdown :text="getPageSizeText(value)" right menu-class="gl-w-auto! gl-min-w-0">
    <gl-dropdown-item
      v-for="pageSize in $options.PAGE_SIZES"
      :key="pageSize"
      @click="emitInput(pageSize)"
    >
      <span class="gl-white-space-nowrap">{{ getPageSizeText(pageSize) }}</span>
    </gl-dropdown-item>
  </gl-dropdown>
</template>
