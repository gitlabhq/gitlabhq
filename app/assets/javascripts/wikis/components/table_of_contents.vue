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
  <div class="gl-border-t gl-mt-6">
    <h2 class="gl-mt-4 gl-pl-3 gl-text-lg">{{ __('On this page') }}</h2>
    <div
      ref="toc"
      class="gl-my-3 gl-rounded-base gl-border-1 gl-border-solid gl-border-default gl-bg-subtle gl-px-3"
    >
      <ul class="wiki-pages gl-text-sm">
        <table-of-contents-heading
          v-for="(heading, index) in headings"
          :key="index"
          :heading="heading"
        />
      </ul>
    </div>
  </div>
</template>
