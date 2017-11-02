<script>
  import tooltip from '../../directives/tooltip';
  import toolbarButton from './toolbar_button.vue';

  export default {
    props: {
      previewMarkdown: {
        type: Boolean,
        required: true,
      },
    },
    directives: {
      tooltip,
    },
    components: {
      toolbarButton,
    },
    methods: {
      isMarkdownForm(form) {
        return form && !form.find('.js-vue-markdown-field').length;
      },

      previewMarkdownTab(event, form) {
        if (event.target.blur) event.target.blur();
        if (this.isMarkdownForm(form)) return;

        this.$emit('preview-markdown');
      },

      writeMarkdownTab(event, form) {
        if (event.target.blur) event.target.blur();
        if (this.isMarkdownForm(form)) return;

        this.$emit('write-markdown');
      },
    },
    mounted() {
      $(document).on('markdown-preview:show.vue', this.previewMarkdownTab);
      $(document).on('markdown-preview:hide.vue', this.writeMarkdownTab);
    },
    beforeDestroy() {
      $(document).off('markdown-preview:show.vue', this.previewMarkdownTab);
      $(document).off('markdown-preview:hide.vue', this.writeMarkdownTab);
    },
  };
</script>

<template>
  <div class="md-header">
    <ul class="nav-links clearfix">
      <li :class="{ active: !previewMarkdown }">
        <a
          class="js-write-link"
          href="#md-write-holder"
          tabindex="-1"
          @click.prevent="writeMarkdownTab($event)">
          Write
        </a>
      </li>
      <li :class="{ active: previewMarkdown }">
        <a
          class="js-preview-link"
          href="#md-preview-holder"
          tabindex="-1"
          @click.prevent="previewMarkdownTab($event)">
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
            v-tooltip
            aria-label="Go full screen"
            class="toolbar-btn js-zen-enter"
            data-container="body"
            tabindex="-1"
            title="Go full screen"
            type="button">
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
