<script>
import { GlDisclosureDropdownGroup } from '@gitlab/ui';
import { PLACES } from '~/vue_shared/global_search/constants';

export default {
  name: 'DefaultPlaces',
  i18n: {
    PLACES,
  },
  components: {
    GlDisclosureDropdownGroup,
  },
  inject: ['contextSwitcherLinks'],
  computed: {
    shouldRender() {
      return this.contextSwitcherLinks.length > 0;
    },
    group() {
      return {
        name: this.$options.i18n.PLACES,
        items: this.contextSwitcherLinks.map(({ title, link }) => ({ text: title, href: link })),
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
  <gl-disclosure-dropdown-group v-if="shouldRender" v-bind="$attrs" :group="group" />
</template>
