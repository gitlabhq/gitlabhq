<script>
  /* global Flash */
  import markdownHeader from './header.vue';
  import markdownToolbar from './toolbar.vue';

  export default {
    props: {
      markdownPreviewUrl: {
        type: String,
        required: false,
        default: '',
      },
      markdownDocs: {
        type: String,
        required: true,
      },
    },
    data() {
      return {
        markdownPreview: '',
        markdownPreviewLoading: false,
        previewMarkdown: false,
      };
    },
    components: {
      markdownHeader,
      markdownToolbar,
    },
    methods: {
      toggleMarkdownPreview() {
        this.previewMarkdown = !this.previewMarkdown;

        if (!this.previewMarkdown) {
          this.markdownPreview = '';
        } else {
          this.markdownPreviewLoading = true;
          this.$http.post(
            this.markdownPreviewUrl,
            {
              /*
                Can't use `$refs` as the component is technically in the parent component
                so we access the VNode & then get the element
              */
              text: this.$slots.textarea[0].elm.value,
            },
          )
          .then(resp => resp.json())
          .then((data) => {
            this.markdownPreviewLoading = false;
            this.markdownPreview = data.body;

            this.$nextTick(() => {
              $(this.$refs['markdown-preview']).renderGFM();
            });
          })
          .catch(() => new Flash('Error loading markdown preview'));
        }
      },
    },
    mounted() {
      /*
        GLForm class handles all the toolbar buttons
      */
      return new gl.GLForm($(this.$refs['gl-form']), true);
    },
    beforeDestroy() {
      const glForm = $(this.$refs['gl-form']).data('gl-form');
      if (glForm) {
        glForm.destroy();
      }
    },
  };
</script>

<template>
  <div
    class="md-area prepend-top-default append-bottom-default js-vue-markdown-field"
    ref="gl-form">
    <markdown-header
      :preview-markdown="previewMarkdown"
      @toggle-markdown="toggleMarkdownPreview" />
    <div
      class="md-write-holder"
      v-show="!previewMarkdown">
      <div class="zen-backdrop">
        <slot name="textarea"></slot>
        <a
          class="zen-control zen-control-leave js-zen-leave"
          href="#"
          aria-label="Enter zen mode">
          <i
            class="fa fa-compress"
            aria-hidden="true">
          </i>
        </a>
        <markdown-toolbar
          :markdown-docs="markdownDocs" />
      </div>
    </div>
    <div
      class="md md-preview-holder md-preview"
      v-show="previewMarkdown">
      <div
        ref="markdown-preview"
        v-html="markdownPreview">
      </div>
      <span v-if="markdownPreviewLoading">
        Loading...
      </span>
    </div>
  </div>
</template>
