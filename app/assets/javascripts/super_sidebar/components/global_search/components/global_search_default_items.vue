<script>
import { GlDisclosureDropdownGroup } from '@gitlab/ui';
import { mapState, mapGetters } from 'vuex';
import { ALL_GITLAB, PLACES } from '~/vue_shared/global_search/constants';

export default {
  name: 'GlobalSearchDefaultItems',
  i18n: {
    ALL_GITLAB,
    PLACES,
  },
  components: {
    GlDisclosureDropdownGroup,
  },
  inject: ['contextSwitcherLinks'],
  computed: {
    ...mapState(['searchContext']),
    ...mapGetters(['defaultSearchOptions']),
    currentContextName() {
      return (
        this.searchContext?.project?.name ||
        this.searchContext?.group?.name ||
        this.$options.i18n.ALL_GITLAB
      );
    },
    groups() {
      const groups = [
        {
          name: this.$options.i18n.PLACES,
          items: this.contextSwitcherLinks.map(({ title, link }) => ({ text: title, href: link })),
        },
        {
          name: this.currentContextName,
          items: this.defaultSearchOptions,
        },
      ];

      return groups.filter(({ items }) => items.length > 0);
    },
  },
};
</script>

<template>
  <ul class="gl-p-0 gl-m-0 gl-list-style-none">
    <gl-disclosure-dropdown-group
      v-for="(group, index) of groups"
      :key="group.name"
      :group="group"
      bordered
      :class="{ 'gl-mt-0!': index === 0 }"
    />
  </ul>
</template>
