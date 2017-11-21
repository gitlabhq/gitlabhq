<script>
  import { mapActions, mapGetters } from 'vuex';
  import tooltip from '../../vue_shared/directives/tooltip';

  export default {
    directives: {
      tooltip,
    },
    computed: {
      ...mapGetters([
        'activeFile',
      ]),
      blobContentElementSelector() {
        return `.blob-content[data-blob-id='${this.activeFile.id}']`;
      },
      copySourceButtonDisabled() {
        return this.activeFile.simple.html === '';
      },
      copySourceButtonTitle() {
        if (this.activeFile.simple.loading) {
          return 'Wait for the source to load to copy it to the clipboard';
        }

        return this.activeFile.currentViewer !== 'simple' ? 'Switch to source to copy it to clipboard' : 'Copy source to clipboard';
      },
    },
    methods: {
      ...mapActions([
        'changeFileViewer',
      ]),
      clickCopy(e) {
        if (this.activeFile.currentViewer !== 'simple' && this.activeFile.simple.html !== '') {
          e.stopPropagation();

          return this.changeFileViewer({
            file: this.activeFile,
            type: 'simple',
          }).then(() => {
            // HACK: This ensures that the DOM has been updated before allowing Clipboard.js
            // to actually copy the content
            // Without this sometimes the DOM may not be updated but the clipboard.js has triggered
            // a click listener & then throwing an error
            setTimeout(() => {
              this.$refs.clipboardBtn.click();
            });
          });
        } else if (this.activeFile.currentViewer !== 'simple' && this.activeFile.simple.html === '') {
          e.stopPropagation();
          return false;
        }

        return true;
      },
    },
  };
</script>

<template>
  <button
    v-tooltip
    type="button"
    class="btn btn-default btn-sm js-copy-blob-source-btn"
    :class="{
      disabled: copySourceButtonDisabled,
    }"
    :title="copySourceButtonTitle"
    :aria-label="copySourceButtonTitle"
    data-container="body"
    :data-clipboard-target="blobContentElementSelector"
    @click="clickCopy($event)"
    ref="clipboardBtn"
  >
    <i
      aria-hidden="true"
      class="fa fa-clipboard"
    >
    </i>
  </button>
</template>
