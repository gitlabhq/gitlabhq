<script>
import { GlLabel } from '@gitlab/ui';
import { ABUSE_CATEGORIES } from '../constants';

export default {
  name: 'AbuseCategory',
  components: {
    GlLabel,
  },
  props: {
    category: {
      type: String,
      required: true,
    },
  },
  computed: {
    categoryObject() {
      return ABUSE_CATEGORIES[this.category];
    },
  },
};
</script>

<template>
  <gl-label
    v-if="categoryObject"
    :background-color="categoryObject.backgroundColor"
    :title="categoryObject.title"
    :target="null"
    :class="categoryObject.textColor"
  />
</template>
