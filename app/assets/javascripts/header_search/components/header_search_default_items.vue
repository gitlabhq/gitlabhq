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
};
</script>

<template>
  <div>
    <gl-dropdown-section-header>{{ sectionHeader }}</gl-dropdown-section-header>
    <gl-dropdown-item
      v-for="(option, index) in defaultSearchOptions"
      :id="`default-${index}`"
      :key="index"
      tabindex="-1"
      :href="option.url"
    >
      {{ option.title }}
    </gl-dropdown-item>
  </div>
</template>
