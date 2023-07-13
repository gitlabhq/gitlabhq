<script>
import { GlDisclosureDropdownItem } from '@gitlab/ui';

import { I18N_EDIT } from '../constants';

export default {
  name: 'RunnerEditDisclosureDropdownItem',
  components: {
    GlDisclosureDropdownItem,
  },
  props: {
    href: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    item() {
      return { text: I18N_EDIT, href: this.href };
    },
  },
  I18N_EDIT,
};
</script>

<template>
  <gl-disclosure-dropdown-item v-if="href" :item="item" />
</template>
