<script>
  import tooltip from '../../directives/tooltip';
  import toolbarButton from './toolbar_button.vue';

  export default {
    data() {
      return {
        floatingModeEnabled: false,
      };
    },
    props: {
      previewMarkdown: {
        type: Boolean,
        required: true,
      },
      enabledFloatingMode: {
        type: Boolean,
        required: false,
        default: false,
      },
    },
    directives: {
      tooltip,
    },
    components: {
      toolbarButton,
    },
    methods: {
      toggleMarkdownPreview(e, form) {
        if (form && !form.find('.js-vue-markdown-field').length) {
          return;
        } else if (e.target.blur) {
          e.target.blur();
        }

        this.$emit('toggle-markdown');
      },
      toggleFloatingMode() {
        this.floatingModeEnabled = !this.floatingModeEnabled;
        this.$refs.floatingModeBtn.blur();

        this.$emit('toggleFloatingMode');
      },
      toggleFullScreen() {
        if (this.floatingModeEnabled) {
          this.toggleFloatingMode();
        }
      },
    },
    mounted() {
      $(document).on('markdown-preview:show.vue', this.toggleMarkdownPreview);
      $(document).on('markdown-preview:hide.vue', this.toggleMarkdownPreview);
    },
    beforeDestroy() {
      $(document).on('markdown-preview:show.vue', this.toggleMarkdownPreview);
      $(document).off('markdown-preview:hide.vue', this.toggleMarkdownPreview);
    },
  };
</script>

<template>
  <div class="md-header">
    <ul class="nav-links clearfix">
      <li :class="{ active: !previewMarkdown }">
        <a
          href="#md-write-holder"
          tabindex="-1"
          @click.prevent="toggleMarkdownPreview($event)">
          Write
        </a>
      </li>
      <li :class="{ active: previewMarkdown }">
        <a
          href="#md-preview-holder"
          tabindex="-1"
          @click.prevent="toggleMarkdownPreview($event)">
          Preview
        </a>
      </li>
      <li class="pull-right">
        <div class="toolbar-group">
          <toolbar-button
            tag="**"
            button-title="Add bold text"
            icon="bold" />
          <toolbar-button
            tag="*"
            button-title="Add italic text"
            icon="italic" />
          <toolbar-button
            tag="> "
            :prepend="true"
            button-title="Insert a quote"
            icon="quote-right" />
          <toolbar-button
            tag="`"
            tag-block="```"
            button-title="Insert code"
            icon="code" />
          <toolbar-button
            tag="* "
            :prepend="true"
            button-title="Add a bullet list"
            icon="list-ul" />
          <toolbar-button
            tag="1. "
            :prepend="true"
            button-title="Add a numbered list"
            icon="list-ol" />
          <toolbar-button
            tag="* [ ] "
            :prepend="true"
            button-title="Add a task list"
            icon="check-square-o" />
        </div>
        <div class="toolbar-group">
          <button
            v-if="enabledFloatingMode"
            v-tooltip
            data-container="body"
            aria-label="Toggle floating mode"
            title="Toggle floating mode"
            class="toolbar-btn hidden-xs"
            :class="{ active: floatingModeEnabled }"
            type="button"
            ref="floatingModeBtn"
            @click="toggleFloatingMode"
          >
            <i
              class="fa"
              :class="{
                'fa-window-restore': !floatingModeEnabled,
                'fa-window-maximize': floatingModeEnabled,
              }"
              aria-hidden="true">
            </i>
          </button>
          <button
            v-tooltip
            aria-label="Go full screen"
            class="toolbar-btn js-zen-enter"
            data-container="body"
            tabindex="-1"
            title="Go full screen"
            type="button"
            @click="toggleFullScreen"
          >
            <i
              aria-hidden="true"
              class="fa fa-arrows-alt fa-fw">
            </i>
          </button>
        </div>
      </li>
    </ul>
  </div>
</template>
