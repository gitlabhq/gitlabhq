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
    class="gl-rounded-base gl-border-solid gl-border-1 gl-border-gray-100 gl-p-3 gl-m-3 gl-bg-gray-10"
  >
    <strong class="gl-text-sm gl-py-3">{{ __('On this page') }}</strong>
    <ul class="wiki-pages gl-text-sm">
      <table-of-contents-heading
        v-for="(heading, index) in headings"
        :key="index"
        :heading="heading"
      />
    </ul>
  </div>
</template>
