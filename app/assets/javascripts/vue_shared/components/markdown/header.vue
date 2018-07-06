<script>
  import $ from 'jquery';
  import tooltip from '../../directives/tooltip';
  import toolbarButton from './toolbar_button.vue';
  import icon from '../icon.vue';

  export default {
    directives: {
      tooltip,
    },
    components: {
      toolbarButton,
      icon,
    },
    props: {
      previewMarkdown: {
        type: Boolean,
        required: true,
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
    methods: {
      isValid(form) {
        return !form ||
          form.find('.js-vue-markdown-field').length &&
          $(this.$el).closest('form')[0] === form[0];
      },

      previewMarkdownTab(event, form) {
        if (event.target.blur) event.target.blur();
        if (!this.isValid(form)) return;

        this.$emit('preview-markdown');
      },

      writeMarkdownTab(event, form) {
        if (event.target.blur) event.target.blur();
        if (!this.isValid(form)) return;

        this.$emit('write-markdown');
      },
    },
  };
</script>

<template>
  <div class="md-header">
    <ul class="nav-links clearfix">
      <li
        :class="{ active: !previewMarkdown }"
        class="md-header-tab"
      >
        <a
          class="js-write-link"
          href="#md-write-holder"
          tabindex="-1"
          @click.prevent="writeMarkdownTab($event)"
        >
          Write
        </a>
      </li>
      <li
        :class="{ active: previewMarkdown }"
        class="md-header-tab"
      >
        <a
          class="js-preview-link js-md-preview-button"
          href="#md-preview-holder"
          tabindex="-1"
          @click.prevent="previewMarkdownTab($event)"
        >
          Preview
        </a>
      </li>
      <li
        :class="{ active: !previewMarkdown }"
        class="md-header-toolbar"
      >
        <toolbar-button
          tag="**"
          button-title="Add bold text"
          icon="bold"
        />
        <toolbar-button
          tag="*"
          button-title="Add italic text"
          icon="italic"
        />
        <toolbar-button
          :prepend="true"
          tag="> "
          button-title="Insert a quote"
          icon="quote"
        />
        <toolbar-button
          tag="`"
          tag-block="```"
          button-title="Insert code"
          icon="code"
        />
        <toolbar-button
          :prepend="true"
          tag="* "
          button-title="Add a bullet list"
          icon="list-bulleted"
        />
        <toolbar-button
          :prepend="true"
          tag="1. "
          button-title="Add a numbered list"
          icon="list-numbered"
        />
        <toolbar-button
          :prepend="true"
          tag="* [ ] "
          button-title="Add a task list"
          icon="task-done"
        />
        <button
          v-tooltip
          aria-label="Go full screen"
          class="toolbar-btn toolbar-fullscreen-btn js-zen-enter"
          data-container="body"
          tabindex="-1"
          title="Go full screen"
          type="button"
        >
          <icon
            name="screen-full"
          />
        </button>
      </li>
    </ul>
  </div>
</template>
