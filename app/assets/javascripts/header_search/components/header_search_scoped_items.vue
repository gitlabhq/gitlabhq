<script>
import { GlDropdownItem } from '@gitlab/ui';
import { mapState, mapGetters } from 'vuex';

export default {
  name: 'HeaderSearchScopedItems',
  components: {
    GlDropdownItem,
  },
  props: {
    currentFocusedOption: {
      type: Object,
      required: false,
      default: () => null,
    },
  },
  computed: {
    ...mapState(['search']),
    ...mapGetters(['scopedSearchOptions']),
  },
  methods: {
    isOptionFocused(option) {
      return this.currentFocusedOption?.html_id === option.html_id;
    },
  },
};
</script>

<template>
  <div>
    <gl-dropdown-item
      v-for="option in scopedSearchOptions"
      :ref="option.html_id"
      :key="option.html_id"
      :class="{ 'gl-bg-gray-50': isOptionFocused(option) }"
      tabindex="-1"
      :href="option.url"
    >
      "<span class="gl-font-weight-bold">{{ search }}</span
      >" {{ option.description }}
      <span v-if="option.scope" class="gl-font-style-italic">{{ option.scope }}</span>
    </gl-dropdown-item>
  </div>
</template>
