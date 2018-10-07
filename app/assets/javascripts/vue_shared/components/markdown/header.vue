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
      mode: {
        type: String,
        required: true,
      },
    },
    computed: {
      mdTable() {
        return [
          '| header | header |',
          '| ------ | ------ |',
          '| cell | cell |',
          '| cell | cell |',
        ].join('\n');
      },
    },
    mounted() {
      $(document).on('markdown-preview:show.vue', this.previewTab);
      $(document).on('markdown-preview:hide.vue', this.markdownTab);
    },
    beforeDestroy() {
      $(document).off('markdown-preview:show.vue', this.previewTab);
      $(document).off('markdown-preview:hide.vue', this.markdownTab);
    },
    methods: {
      isValid(form) {
        return !form ||
          form.find('.js-vue-markdown-field').length &&
          $(this.$el).closest('form')[0] === form[0];
      },

      previewTab(event, form) {
        if (event.target.blur) event.target.blur();
        if (!this.isValid(form)) return;

        this.$emit('preview');
      },

      markdownTab(event, form) {
        if (event.target.blur) event.target.blur();
        if (!this.isValid(form)) return;

        this.$emit('markdown');
      },

      richTab(event, form) {
        if (event.target.blur) event.target.blur();
        if (!this.isValid(form)) return;

        this.$emit('rich');
      },

      toolbarButtonClicked(button) {
        this.$emit('toolbarButtonClicked', button);
      }
    },
  };
</script>

<template>
  <div class="md-header">
    <ul class="nav-links clearfix">
      <li
        :class="{ active: mode == 'markdown' }"
        class="md-header-tab"
      >
        <a
          class="js-write-link"
          href="#md-write-holder"
          tabindex="-1"
          @click.prevent="markdownTab($event)"
        >
          Markdown
        </a>
      </li>
      <li
        :class="{ active: mode == 'rich' }"
        class="md-header-tab"
      >
        <a
          class="js-rich-link"
          href="#md-rich-holder"
          tabindex="-1"
          @click.prevent="richTab($event)"
        >
          Rich
        </a>
      </li>
      <li
        :class="{ active: mode == 'preview' }"
        class="md-header-tab"
      >
        <a
          class="js-preview-link"
          href="#md-preview-holder"
          tabindex="-1"
          @click.prevent="previewTab($event)"
        >
          Preview
        </a>
      </li>
      <li
        :class="{ active: mode != 'preview' }"
        class="md-header-toolbar"
      >
        <toolbar-button
          @click="toolbarButtonClicked"
          tag="**"
          button-title="Add bold text"
          icon="bold"
        />
        <toolbar-button
          @click="toolbarButtonClicked"
          tag="*"
          button-title="Add italic text"
          icon="italic"
        />
        <toolbar-button
          @click="toolbarButtonClicked"
          :prepend="true"
          tag="> "
          button-title="Insert a quote"
          icon="quote"
        />
        <toolbar-button
          @click="toolbarButtonClicked"
          tag="`"
          tag-block="```"
          button-title="Insert code"
          icon="code"
        />
        <toolbar-button
          v-if="mode == 'markdown'"
          @click="toolbarButtonClicked"
          tag="[{text}](url)"
          tag-select="url"
          button-title="Add a link"
          icon="link"
        />
        <toolbar-button
          @click="toolbarButtonClicked"
          :prepend="true"
          tag="* "
          button-title="Add a bullet list"
          icon="list-bulleted"
        />
        <toolbar-button
          @click="toolbarButtonClicked"
          :prepend="true"
          tag="1. "
          button-title="Add a numbered list"
          icon="list-numbered"
        />
        <toolbar-button
          v-if="mode == 'markdown'"
          @click="toolbarButtonClicked"
          :prepend="true"
          tag="* [ ] "
          button-title="Add a task list"
          icon="task-done"
        />
        <toolbar-button
          v-if="mode == 'markdown'"
          :tag="mdTable"
          :prepend="true"
          :button-title="__('Add a table')"
          icon="table"
        />
        <button
          v-if="mode == 'markdown'"
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
