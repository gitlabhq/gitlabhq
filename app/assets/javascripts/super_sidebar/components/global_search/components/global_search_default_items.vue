<script>
import { GlDisclosureDropdownGroup } from '@gitlab/ui';
import { mapState, mapGetters } from 'vuex';
import { ALL_GITLAB } from '~/vue_shared/global_search/constants';

export default {
  name: 'GlobalSearchDefaultItems',
  i18n: {
    ALL_GITLAB,
  },
  components: {
    GlDisclosureDropdownGroup,
  },
  computed: {
    ...mapState(['searchContext']),
    ...mapGetters(['defaultSearchOptions']),
    sectionHeader() {
      return (
        this.searchContext?.project?.name ||
        this.searchContext?.group?.name ||
        this.$options.i18n.ALL_GITLAB
      );
    },
    defaultItemsGroup() {
      return {
        name: this.sectionHeader,
        items: this.defaultSearchOptions,
      };
    },
  },
};
</script>

<template>
  <ul class="gl-p-0 gl-m-0 gl-list-style-none">
    <gl-disclosure-dropdown-group :group="defaultItemsGroup" bordered class="gl-mt-0!" />
  </ul>
</template>
