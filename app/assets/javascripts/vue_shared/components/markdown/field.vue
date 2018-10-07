<script>
  import $ from 'jquery';
  import { Editor } from 'tiptap'
  import {
    HistoryExtension,
    PlaceholderExtension,

    BoldMark,
    ItalicMark,
    LinkMark,

    BulletListNode,
    HardBreakNode,
    HeadingNode,
    ListItemNode,
    OrderedListNode,
  } from 'tiptap-extensions'
  import { s__ } from '~/locale';
  import Flash from '../../../flash';
  import GLForm from '../../../gl_form';
  import { CopyAsGFM } from '../../../behaviors/markdown/copy_as_gfm';
  import markdownHeader from './header.vue';
  import markdownToolbar from './toolbar.vue';
  import icon from '../icon.vue';
  import { updateMarkdownText } from '../../../lib/utils/text_markdown';
  import InlineDiffMark from './marks/inline_diff';
  import InlineHTMLMark from './marks/inline_html';
  import StrikeMark from './marks/strike';
  import CodeMark from './marks/code';
  import MathMark from './marks/math';
  import EmojiNode from './nodes/emoji';
  import HorizontalRuleNode from './nodes/horizontal_rule.js';
  import ReferenceNode from './nodes/reference';
  import BlockquoteNode from './nodes/blockquote';
  import CodeBlockNode from './nodes/code_block';
  import ImageNode from './nodes/image';
  import VideoNode from './nodes/video';
  import DetailsNode from './nodes/details';
  import SummaryNode from './nodes/summary';
  import markdownSerializer from './markdown_serializer';

  export default {
    components: {
      Editor,
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
        rendered: '',
        referencedCommands: '',
        referencedUsers: '',
        renderedLoading: false,
        mode: 'markdown',
        editorExtensions: [
          new HistoryExtension,
          new PlaceholderExtension,

          // new TableOfContentsNode,
          new EmojiNode,
          new VideoNode,
          new DetailsNode,
          new SummaryNode,
          new ReferenceNode,
          new HorizontalRuleNode,
          // new TableNode,
          // new TableHeadNode,
          // new TableRowNode,
          // new TableCellNode,
          // new TodoItemNode,
          // new TodoListNode,

          new BlockquoteNode,
          new BulletListNode,
          new CodeBlockNode,
          new HeadingNode({ maxLevel: 6 }),
          new HardBreakNode,
          new ImageNode,
          new ListItemNode,
          new OrderedListNode,

          new BoldMark,
          new LinkMark,
          new ItalicMark,
          new StrikeMark,

          new InlineDiffMark,
          new InlineHTMLMark,
          new MathMark,
          new CodeMark,

          // new SuggestionsPlugin,
          // new MentionNode,
        ]
      };
    },
    watch: {
      rendered(newRendered, oldRendered) {
        if (newRendered.length) {
          this.$refs.editor.setContent(newRendered);
        } else {
          this.$refs.editor.clearContent(true);
        }
      }
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
        snippets: this.enableAutocomplete,
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
        if (this.mode == 'rich') {
          this.getTextFromEditor();
        }

        this.mode = 'preview';

        this.renderMarkdown();
      },

      showRichTab() {
        this.mode = 'rich';

        this.renderMarkdown();
      },

      showMarkdownTab() {
        // TODO: Better event handling around switching tabs. Old mode/new mode?
        if (this.mode == 'rich') {
          this.getTextFromEditor();
        }

        this.rendered = '';
        this.mode = 'markdown';
      },

      getTextFromEditor() {
        // const html = this.$refs.editor.getHTML();
        // var node = document.createElement('div');
        // $(html).each(function() { node.appendChild(this) });
        // const markdown = CopyAsGFM.nodeToGFM(node);

        const doc = this.$refs.editor.getDocument();
        const markdown = markdownSerializer.serialize(doc);

        // TODO: Only works with CommentForm
        this.$parent.note = markdown || '';
      },

      renderMarkdown() {
        // TODO: Only works with CommentForm
        const text = this.$parent.note;

        if (text) {
          this.renderedLoading = true;
          this.$http
            .post(this.versionedRenderPath(), { text })
              .then(resp => resp.json())
              .then(data => this.updateRendered(data))
              .catch(() => new Flash(s__('Error loading markdown preview')));
        } else {
          this.updateRendered();
        }
      },

      updateRendered(data = {}) {
        this.renderedLoading = false;
        this.rendered = data.body || "";

        if (data.references) {
          this.referencedCommands = data.references.commands;
          this.referencedUsers = data.references.users;
        }

        this.$nextTick(() => {
          $(this.$refs['markdown-preview']).renderGFM();
        });
      },

      versionedRenderPath() {
        const { markdownPreviewPath, markdownVersion } = this;
        return `${markdownPreviewPath}${
          markdownPreviewPath.indexOf('?') === -1 ? '?' : '&'
          }markdown_version=${markdownVersion}`;
      },

      toolbarButtonClicked(button) {
        if (this.mode == 'markdown') {
          updateMarkdownText({
            textArea: this.$slots.textarea[0].elm,
            tag: button.tag,
            blockTag: button.block,
            wrap: !button.prepend,
            select: button.select
          });
        } else {
          const menuActions = this.$refs.editor.menuActions;
          switch(button.tag) {
            case '**':
              menuActions.marks.bold.command();
              break;
            case '*':
              menuActions.marks.italic.command();
              break;
            case '> ':
              menuActions.nodes.blockquote.command();
              break;
            case '`':
              menuActions.marks.code.command();
              break;
            case '[{text}](url)':
              menuActions.marks.link.command();
              break;
            case '* ':
              menuActions.nodes.bullet_list.command();
              break;
            case '1. ':
              menuActions.nodes.ordered_list.command();
              break;
            case '* [ ] ':
              menuActions.nodes.todo_list.command();
              break;
          }
        }
      }
    },
  };
</script>

<template>
  <div
    ref="gl-form"
    :class="{ 'prepend-top-default append-bottom-default': addSpacingClasses }"
    class="md-area js-vue-markdown-field">
    <markdown-header
      :mode="mode"
      @preview="showPreviewTab"
      @markdown="showMarkdownTab"
      @rich="showRichTab"
      @toolbarButtonClicked="toolbarButtonClicked"
    />
    <div
      v-show="mode == 'markdown'"
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
      v-show="mode == 'rich'"
      class="md-rich-editor md md-preview-holder"
    >
      <editor
        ref="editor"
        :class="['editor', { 'editable': !renderedLoading }]"
        :extensions="editorExtensions"
        :editable="!renderedLoading"
      >
        <div slot="content" slot-scope="props"></div>
      </editor>
      <span v-if="renderedLoading">
        Loading...
      </span>
    </div>
    <div
      v-show="mode == 'preview'"
      class="md md-preview-holder md-preview js-vue-md-preview"
    >
      <div
        ref="markdown-preview"
        v-html="rendered"
      >
      </div>
      <span v-if="!renderedLoading && rendered.length == 0">
        Nothing to preview
      </span>
      <span v-if="renderedLoading">
        Loading...
      </span>
    </div>
    <template v-if="mode == 'preview' && !renderedLoading">
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
