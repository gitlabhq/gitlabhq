<script>
  import { mapGetters } from 'vuex';
  import { s__, sprintf } from '../../../locale';

  export default {
    computed: {
      ...mapGetters([
        'activeFile',
        'activeFileCurrentViewer',
      ]),
      renderErrorContent() {
        const name = this.activeFileCurrentViewer.name;
        const error = this.activeFileCurrentViewer.renderError;

        return sprintf(
          s__('BlobViewer|The %{name} could not be displayed because %{error}. You can %{link} download it instead.'), {
            name,
            error,
            link: `<a href="${this.activeFile.rawPath}" download rel="noopener noreferrer" target="_blank">
              ${s__('BlobViewer|download it')}
            </a>`,
          },
          false,
        );
      },
    },
  };
</script>

<template>
  <div
    class="nothing-here-block"
    v-html="renderErrorContent"
  >
  </div>
</template>
