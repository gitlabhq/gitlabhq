<script>
  /* global Flash */
  import markdownHeader from './header.vue';
  import markdownToolbar from './toolbar.vue';

  const REFERENCED_USERS_THRESHOLD = 10;

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
      addSpacingClasses: {
        type: Boolean,
        required: false,
        default: true,
      },
      quickActionsDocs: {
        type: String,
        required: false,
      },
    },
    data() {
      return {
        markdownPreview: '',
        referencedCommands: '',
        referencedUsers: '',
        markdownPreviewLoading: false,
        previewMarkdown: false,
      };
    },
    components: {
      markdownHeader,
      markdownToolbar,
    },
    computed: {
      shouldShowReferencedUsers() {
        return this.referencedUsers.length >= REFERENCED_USERS_THRESHOLD;
      },
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
            this.referencedCommands = data.references.commands;
            this.referencedUsers = data.references.users;

            if (!this.markdownPreview) {
              this.markdownPreview = 'Nothing to preview.';
            }

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
    class="md-area js-vue-markdown-field"
    :class="{ 'prepend-top-default append-bottom-default': addSpacingClasses }"
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
          :markdown-docs="markdownDocs"
          :quick-actions-docs="quickActionsDocs"
          />
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
    <template v-if="previewMarkdown && !markdownPreviewLoading">
      <div
        v-if="referencedCommands"
        v-html="referencedCommands"
        class="referenced-commands"></div>
      <div
        v-if="shouldShowReferencedUsers"
        class="referenced-users">
          <span>
            <i
              class="fa fa-exclamation-triangle"
              aria-hidden="true">
            </i>
            You are about to add
            <strong>
              <span class="js-referenced-users-count">
                {{referencedUsers.length}}
              </span>
            </strong> people to the discussion. Proceed with caution.
          </span>
        </div>
    </template>
  </div>
</template>
