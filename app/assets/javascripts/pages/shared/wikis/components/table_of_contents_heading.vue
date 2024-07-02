<script>
export default {
  name: 'TableOfContentsHeading',
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
    <a :href="heading.href" class="gl-str-truncated">
      {{ heading.text }}
    </a>

    <ul v-if="heading.subHeadings.length" dir="auto" class="!gl-pl-3">
      <table-of-contents-heading
        v-for="(child, index) in heading.subHeadings"
        :key="index"
        :heading="child"
      />
    </ul>
  </li>
</template>
