<script>
  import $ from 'jquery';
  import { s__ } from '~/locale';
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
      markdownVersion: {
        type: Number,
        required: false,
        default: 0,
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
      return new GLForm($(this.$refs['gl-form']), {
        emojis: this.enableAutocomplete,
        members: this.enableAutocomplete,
        issues: this.enableAutocomplete,
        mergeRequests: this.enableAutocomplete,
        epics: this.enableAutocomplete,
        milestones: this.enableAutocomplete,
        labels: this.enableAutocomplete,
      });
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
          this.$http
            .post(this.versionedPreviewPath(), { text })
              .then(resp => resp.json())
              .then(data => this.renderMarkdown(data))
              .catch(() => new Flash(s__('Error loading markdown preview')));
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

      versionedPreviewPath() {
        const { markdownPreviewPath, markdownVersion } = this;
        return `${markdownPreviewPath}${
          markdownPreviewPath.indexOf('?') === -1 ? '?' : '&'
          }markdown_version=${markdownVersion}`;
      },
    },
  };
</script>

<template>
  <div
    ref="gl-form"
    :class="{ 'prepend-top-default append-bottom-default': addSpacingClasses }"
    class="md-area js-vue-markdown-field">
    <markdown-header
      :preview-markdown="previewMarkdown"
      @preview-markdown="showPreviewTab"
      @write-markdown="showWriteTab"
    />
    <div
      v-show="!previewMarkdown"
      class="md-write-holder"
    >
      <div class="zen-backdrop">
        <slot name="textarea"></slot>
        <a
          class="zen-control zen-control-leave js-zen-leave"
          href="#"
          aria-label="Enter zen mode"
        >
          <icon
            :size="32"
            name="screen-normal"
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
      v-show="previewMarkdown"
      class="md md-preview-holder md-preview js-vue-md-preview"
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
        class="referenced-commands"
        v-html="referencedCommands"
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
