<script>
  import $ from 'jquery';
  import Flash from '../../../flash';
  import GLForm from '../../../gl_form';
  import markdownHeader from './header.vue';
  import markdownToolbar from './toolbar.vue';
  import icon from '../icon.vue';

  export default {
    components: {
      markdownHeader,
      markdownToolbar,
      icon,
    },
    props: {
      markdownPreviewPath: {
        type: String,
        required: false,
        default: '',
      },
      markdownDocsPath: {
        type: String,
        required: true,
      },
      addSpacingClasses: {
        type: Boolean,
        required: false,
        default: true,
      },
      quickActionsDocsPath: {
        type: String,
        required: false,
        default: '',
      },
      canAttachFile: {
        type: Boolean,
        required: false,
        default: true,
      },
      enableAutocomplete: {
        type: Boolean,
        required: false,
        default: true,
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
    computed: {
      shouldShowReferencedUsers() {
        const referencedUsersThreshold = 10;
        return this.referencedUsers.length >= referencedUsersThreshold;
      },
    },
    mounted() {
      /*
        GLForm class handles all the toolbar buttons
      */
      return new GLForm($(this.$refs['gl-form']), this.enableAutocomplete);
    },
    beforeDestroy() {
      const glForm = $(this.$refs['gl-form']).data('glForm');
      if (glForm) {
        glForm.destroy();
      }
    },
    methods: {
      showPreviewTab() {
        if (this.previewMarkdown) return;

        this.previewMarkdown = true;

        /*
          Can't use `$refs` as the component is technically in the parent component
          so we access the VNode & then get the element
        */
        const text = this.$slots.textarea[0].elm.value;

        if (text) {
          this.markdownPreviewLoading = true;
          this.$http.post(this.markdownPreviewPath, { text })
            .then(resp => resp.json())
            .then(data => this.renderMarkdown(data))
            .catch(() => new Flash('Error loading markdown preview'));
        } else {
          this.renderMarkdown();
        }
      },

      showWriteTab() {
        this.markdownPreview = '';
        this.previewMarkdown = false;
      },

      renderMarkdown(data = {}) {
        this.markdownPreviewLoading = false;
        this.markdownPreview = data.body || 'Nothing to preview.';

        if (data.references) {
          this.referencedCommands = data.references.commands;
          this.referencedUsers = data.references.users;
        }

        this.$nextTick(() => {
          $(this.$refs['markdown-preview']).renderGFM();
        });
      },
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
      @preview-markdown="showPreviewTab"
      @write-markdown="showWriteTab"
    />
    <div
      class="md-write-holder"
      v-show="!previewMarkdown"
    >
      <div class="zen-backdrop">
        <slot name="textarea"></slot>
        <a
          class="zen-control zen-control-leave js-zen-leave"
          href="#"
          aria-label="Enter zen mode"
        >
          <icon
            name="screen-normal"
            :size="32"
          />
        </a>
        <markdown-toolbar
          :markdown-docs-path="markdownDocsPath"
          :quick-actions-docs-path="quickActionsDocsPath"
          :can-attach-file="canAttachFile"
        />
      </div>
    </div>
    <div
      class="md md-preview-holder md-preview"
      v-show="previewMarkdown"
    >
      <div
        ref="markdown-preview"
        v-html="markdownPreview"
      >
      </div>
      <span v-if="markdownPreviewLoading">
        Loading...
      </span>
    </div>
    <template v-if="previewMarkdown && !markdownPreviewLoading">
      <div
        v-if="referencedCommands"
        v-html="referencedCommands"
        class="referenced-commands"
      >
      </div>
      <div
        v-if="shouldShowReferencedUsers"
        class="referenced-users"
      >
        <span>
          <i
            class="fa fa-exclamation-triangle"
            aria-hidden="true"
          >
          </i>
          You are about to add
          <strong>
            <span class="js-referenced-users-count">
              {{ referencedUsers.length }}
            </span>
          </strong> people to the discussion. Proceed with caution.
        </span>
      </div>
    </template>
  </div>
</template>
