<script>
import { GlLink } from '@gitlab/ui';

export default {
  name: 'TableOfContentsHeading',
  components: {
    GlLink,
  },
  props: {
    heading: {
      type: Object,
      required: true,
    },
  },
};
</script>
<template>
  <li dir="auto">
    <h6>
      <gl-link :href="heading.href" class="gl-str-truncated">
        {{ heading.text }}
      </gl-link>
    </h6>

    <ul v-if="heading.subHeadings.length" dir="auto" class="!gl-pl-3">
      <table-of-contents-heading
        v-for="(child, index) in heading.subHeadings"
        :key="index"
        :heading="child"
      />
    </ul>
  </li>
</template>
