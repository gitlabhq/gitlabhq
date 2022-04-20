<script>
import { GlDropdownItem, GlDropdownDivider } from '@gitlab/ui';
import { mapState, mapGetters } from 'vuex';
import { __, sprintf } from '~/locale';

export default {
  name: 'HeaderSearchScopedItems',
  components: {
    GlDropdownItem,
    GlDropdownDivider,
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
    ...mapGetters(['scopedSearchOptions', 'autocompleteGroupedSearchOptions']),
  },
  methods: {
    isOptionFocused(option) {
      return this.currentFocusedOption?.html_id === option.html_id;
    },
    ariaLabel(option) {
      return sprintf(__('%{search} %{description} %{scope}'), {
        search: this.search,
        description: option.description,
        scope: option.scope || '',
      });
    },
  },
};
</script>

<template>
  <div>
    <gl-dropdown-item
      v-for="option in scopedSearchOptions"
      :id="option.html_id"
      :ref="option.html_id"
      :key="option.html_id"
      :class="{ 'gl-bg-gray-50': isOptionFocused(option) }"
      :aria-selected="isOptionFocused(option)"
      :aria-label="ariaLabel(option)"
      tabindex="-1"
      :href="option.url"
    >
      <span aria-hidden="true">
        "<span class="gl-font-weight-bold">{{ search }}</span
        >" {{ option.description }}
        <span v-if="option.scope" class="gl-font-style-italic">{{ option.scope }}</span>
      </span>
    </gl-dropdown-item>
    <gl-dropdown-divider v-if="autocompleteGroupedSearchOptions.length > 0" />
  </div>
</template>
