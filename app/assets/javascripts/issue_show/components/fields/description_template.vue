<script>
/* eslint-disable @gitlab/vue-require-i18n-strings */
import $ from 'jquery';
import { GlIcon } from '@gitlab/ui';
import IssuableTemplateSelectors from '../../../templates/issuable_template_selectors';

export default {
  components: {
    GlIcon,
  },
  props: {
    formState: {
      type: Object,
      required: true,
    },
    issuableTemplates: {
      type: Array,
      required: false,
      default: () => [],
    },
    projectPath: {
      type: String,
      required: true,
    },
    projectNamespace: {
      type: String,
      required: true,
    },
  },
  computed: {
    issuableTemplatesJson() {
      return JSON.stringify(this.issuableTemplates);
    },
  },
  mounted() {
    // Create the editor for the template
    const editor = document.querySelector('.detail-page-description .note-textarea') || {};
    editor.setValue = val => {
      this.formState.description = val;
    };
    editor.getValue = () => this.formState.description;

    this.issuableTemplate = new IssuableTemplateSelectors({
      $dropdowns: $(this.$refs.toggle),
      editor,
    });
  },
};
</script>

<template>
  <div class="dropdown js-issuable-selector-wrap" data-issuable-type="issue">
    <button
      ref="toggle"
      :data-namespace-path="projectNamespace"
      :data-project-path="projectPath"
      :data-data="issuableTemplatesJson"
      class="dropdown-menu-toggle js-issuable-selector"
      type="button"
      data-field-name="issuable_template"
      data-selected="null"
      data-toggle="dropdown"
    >
      <span class="dropdown-toggle-text">{{ __('Choose a template') }}</span>
      <i aria-hidden="true" class="fa fa-chevron-down"> </i>
    </button>
    <div class="dropdown-menu dropdown-select">
      <div class="dropdown-title gl-display-flex gl-justify-content-center">
        <span class="gl-ml-auto">Choose a template</span>
        <button
          class="dropdown-title-button dropdown-menu-close gl-ml-auto"
          :aria-label="__('Close')"
          type="button"
        >
          <gl-icon name="close" class="dropdown-menu-close-icon" :aria-hidden="true" />
        </button>
      </div>
      <div class="dropdown-input">
        <input
          type="search"
          class="dropdown-input-field"
          :placeholder="__('Filter')"
          autocomplete="off"
        />
        <i aria-hidden="true" class="fa fa-search dropdown-input-search"> </i>
        <gl-icon
          name="close"
          class="dropdown-input-clear js-dropdown-input-clear"
          :aria-label="__('Clear templates search input')"
        />
      </div>
      <div class="dropdown-content"></div>
      <div class="dropdown-footer">
        <ul class="dropdown-footer-list">
          <li>
            <a class="no-template">{{ __('No template') }}</a>
          </li>
          <li>
            <a class="reset-template">{{ __('Reset template') }}</a>
          </li>
        </ul>
      </div>
    </div>
  </div>
</template>
