<script>
import { GlDisclosureDropdownGroup } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapGetters } from 'vuex';
import { ALL_GITLAB } from '~/vue_shared/global_search/constants';
import { OVERLAY_GOTO } from '../command_palette/constants';
import SearchResultHoverLayover from './global_search_hover_overlay.vue';

export default {
  name: 'DefaultIssuables',
  i18n: {
    ALL_GITLAB,
    OVERLAY_GOTO,
  },
  components: {
    GlDisclosureDropdownGroup,
    SearchResultHoverLayover,
  },
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
    shouldRender() {
      return this.group.items.length > 0;
    },
    group() {
      return {
        name: this.currentContextName,
        items: this.defaultSearchOptions?.map((item) => ({
          ...item,
          extraAttrs: {
            class: 'show-hover-layover',
          },
        })),
      };
    },
  },
  created() {
    if (!this.shouldRender) {
      this.$emit('nothing-to-render');
    }
  },
};
</script>

<template>
  <gl-disclosure-dropdown-group v-if="shouldRender" v-bind="$attrs" :group="group">
    <template #list-item="{ item }">
      <search-result-hover-layover :text-message="$options.i18n.OVERLAY_GOTO">
        <span>{{ item.text }}</span>
      </search-result-hover-layover>
    </template>
  </gl-disclosure-dropdown-group>
</template>
