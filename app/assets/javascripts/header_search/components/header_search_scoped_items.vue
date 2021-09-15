<script>
import { GlDropdownItem } from '@gitlab/ui';
import { mapState, mapGetters } from 'vuex';

export default {
  name: 'HeaderSearchScopedItems',
  components: {
    GlDropdownItem,
  },
  computed: {
    ...mapState(['search']),
    ...mapGetters(['scopedSearchOptions']),
  },
};
</script>

<template>
  <div>
    <gl-dropdown-item
      v-for="(option, index) in scopedSearchOptions"
      :id="`scoped-${index}`"
      :key="index"
      tabindex="-1"
      :href="option.url"
    >
      "<span class="gl-font-weight-bold">{{ search }}</span
      >" {{ option.description }}
      <span v-if="option.scope" class="gl-font-style-italic">{{ option.scope }}</span>
    </gl-dropdown-item>
  </div>
</template>
