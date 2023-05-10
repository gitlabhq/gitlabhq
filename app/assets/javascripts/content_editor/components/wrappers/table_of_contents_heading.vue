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
    <a v-if="heading.text" href="#" @click.prevent>
      {{ heading.text }}
    </a>
    <ul v-if="heading.subHeadings.length" dir="auto">
      <table-of-contents-heading
        v-for="(child, index) in heading.subHeadings"
        :key="index"
        :heading="child"
      />
    </ul>
  </li>
</template>
