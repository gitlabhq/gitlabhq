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
        requestAnimationFrame(this.scrollUpdate.bind(this));
        this.updating = true;
      }
    },
    scrollUpdate() {
      const header = document.querySelector('.js-diff-files-changed');
      if (!header) {
        this.updating = false;
        return;
      }

      const { top, bottom } = this.$el.getBoundingClientRect();
      const { top: topOfFixedHeader, bottom: bottomOfFixedHeader } = header.getBoundingClientRect();

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

      this.updating = false;
    },
  },
  computed: {
    isDiscussionsExpanded() {
      return true; // TODO: @fatihacet - Fix this.
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
      :expanded="isExpanded"
      :discussions-expanded="isDiscussionsExpanded"
      :add-merge-request-buttons="true"
      @toggleFile="handleToggle"
      class="js-file-title file-title"
    />
    <diff-content
      v-show="isExpanded"
      :diff-file="file"
    />
    <div
      v-show="!isExpanded"
      class="nothing-here-block diff-collapsed"
    >
      {{ __('This diff is collapsed.') }}
      <button
        @click.prevent="handleToggle"
        class="btn click-to-expand prepend-left-10"
        type="button"
      >
        {{ __('Expand') }}
      </button>
    </div>
  </div>
</template>
