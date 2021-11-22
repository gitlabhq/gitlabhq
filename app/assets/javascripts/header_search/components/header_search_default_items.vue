<script>
import { GlDropdownItem, GlDropdownSectionHeader } from '@gitlab/ui';
import { mapState, mapGetters } from 'vuex';
import { __ } from '~/locale';

export default {
  name: 'HeaderSearchDefaultItems',
  i18n: {
    allGitLab: __('All GitLab'),
  },
  components: {
    GlDropdownSectionHeader,
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
    ...mapState(['searchContext']),
    ...mapGetters(['defaultSearchOptions']),
    sectionHeader() {
      return (
        this.searchContext.project?.name ||
        this.searchContext.group?.name ||
        this.$options.i18n.allGitLab
      );
    },
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
    <gl-dropdown-section-header>{{ sectionHeader }}</gl-dropdown-section-header>
    <gl-dropdown-item
      v-for="option in defaultSearchOptions"
      :ref="option.html_id"
      :key="option.html_id"
      :class="{ 'gl-bg-gray-50': isOptionFocused(option) }"
      tabindex="-1"
      :href="option.url"
    >
      {{ option.title }}
    </gl-dropdown-item>
  </div>
</template>
