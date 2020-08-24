<script>
import { GlIcon } from '@gitlab/ui';
import { DESIGN_ROUTE_NAME } from '../../router/constants';

export default {
  components: {
    GlIcon,
  },
  props: {
    design: {
      type: Object,
      required: false,
      default: null,
    },
    title: {
      type: String,
      required: true,
    },
    iconName: {
      type: String,
      required: true,
    },
  },
  computed: {
    designLink() {
      if (!this.design) return {};

      return {
        name: DESIGN_ROUTE_NAME,
        params: { id: this.design.filename },
        query: this.$route.query,
      };
    },
  },
};
</script>

<template>
  <router-link
    :to="designLink"
    :disabled="!design"
    :class="{ disabled: !design }"
    :aria-label="title"
    class="btn btn-default"
  >
    <gl-icon :name="iconName" />
  </router-link>
</template>
