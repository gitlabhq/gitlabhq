<script>
import TableOfContentsHeading from './table_of_contents_heading.vue';

export default {
  components: {
    TableOfContentsHeading,
  },
  props: {
    headings: {
      type: Array,
      required: true,
    },
  },
};
</script>
<template>
  <div
    ref="toc"
    class="gl-m-3 gl-rounded-base gl-border-1 gl-border-solid gl-border-default gl-bg-subtle gl-p-3"
  >
    <span class="gl-py-3 gl-text-sm">{{ __('On this page') }}</span>
    <ul class="wiki-pages gl-text-sm">
      <table-of-contents-heading
        v-for="(heading, index) in headings"
        :key="index"
        :heading="heading"
      />
    </ul>
  </div>
</template>
