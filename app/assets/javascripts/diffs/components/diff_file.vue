<script>
import diffFileHeader from './diff_file_header.vue';
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
      isActive: false,
    };
  },
  mounted() {
    document.addEventListener('scroll', this.handleScroll);
  },
  beforeDestroy() {
    document.removeEventListener('scroll', this.handleScroll);
  },
  methods: {
    handleToggle() {
      this.isExpanded = !this.isExpanded;
    },
    handleScroll() {
      if (!this.updating) {
        requestAnimationFrame(this.scrollUpdate);
        this.updating = true;
      }
    },
    scrollUpdate() {
      const header = document.querySelector('.sticky-top-bar');
      if (!header) {
        this.updating = false;
        return;
      }

      const { top, bottom } = this.$el.getBoundingClientRect();
      const {
        top: topOfFixedHeader,
        bottom: bottomOfFixedHeader,
      } = header.getBoundingClientRect();

      const headerOverlapsContent = top < topOfFixedHeader && bottom > bottomOfFixedHeader;
      const fullyAboveHeader = bottom < bottomOfFixedHeader;
      const fullyBelowHeader = top > topOfFixedHeader;

      if (headerOverlapsContent && !this.isActive) {
        this.$emit('setActive');
        this.isActive = true;
      } else if (this.isActive && (fullyAboveHeader || fullyBelowHeader)) {
        this.$emit('unsetActive');
        this.isActive = false;
      }

      this.updating = false
    }
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
      :expanded="isExpanded"
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
