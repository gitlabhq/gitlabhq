<script>
import diffFileHeader from '../../notes/components/diff_file_header.vue';
import diffContent from './diff_content.vue';

export default {
  components: {
    diffFileHeader,
    diffContent,
  },
  props: {
    file: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isExpanded: true,
    };
  },
  mounted() {
    document.addEventListener('scroll', () => {
      const { top, bottom } = this.$el.getBoundingClientRect();

      const topOfFixedHeader = 100;
      const bottomOfFixedHeader = 120;

      if (top < topOfFixedHeader && bottom > bottomOfFixedHeader) {
        this.$emit('setActive');
      }

      if (top > bottomOfFixedHeader || bottom < bottomOfFixedHeader) {
        this.$emit('unsetActive');
      }
    });
  },
  methods: {
    handleToggle() {
      this.isExpanded = !this.isExpanded;
    },
  },
};
</script>

<template>
  <div
    class="diff-file file-holder"
    :id="file.fileHash"
  >
    <diff-file-header
      :diff-file="file"
      :collapsible="true"
      :add-merge-request-buttons="true"
      @toggleFile="handleToggle"
      class="js-file-title file-title"
    />
    <diff-content
      v-if="isExpanded"
      :diff-file="file"
    />
    <div
      v-else
      class="nothing-here-block diff-collapsed"
    >
      This diff is collapsed.
      <a
        @click.prevent="handleToggle"
        class="click-to-expand"
        href="#"
      >
        Click to expand it.
      </a>
    </div>
  </div>
</template>
