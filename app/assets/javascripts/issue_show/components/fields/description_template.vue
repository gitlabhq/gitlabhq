<script>
  import $ from 'jquery';
  import IssuableTemplateSelectors from '../../../templates/issuable_template_selectors';

  export default {
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
      editor.setValue = (val) => {
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
  <div
    class="dropdown js-issuable-selector-wrap"
    data-issuable-type="issue">
    <button
      class="dropdown-menu-toggle js-issuable-selector"
      type="button"
      ref="toggle"
      data-field-name="issuable_template"
      data-selected="null"
      data-toggle="dropdown"
      :data-namespace-path="projectNamespace"
      :data-project-path="projectPath"
      :data-data="issuableTemplatesJson">
      <span class="dropdown-toggle-text">
        Choose a template
      </span>
      <i
        aria-hidden="true"
        class="fa fa-chevron-down">
      </i>
    </button>
    <div class="dropdown-menu dropdown-select">
      <div class="dropdown-title">
        Choose a template
        <button
          class="dropdown-title-button dropdown-menu-close"
          aria-label="Close"
          type="button">
          <i
            aria-hidden="true"
            class="fa fa-times dropdown-menu-close-icon">
          </i>
        </button>
      </div>
      <div class="dropdown-input">
        <input
          type="search"
          class="dropdown-input-field"
          placeholder="Filter"
          autocomplete="off" />
        <i
          aria-hidden="true"
          class="fa fa-search dropdown-input-search">
        </i>
        <i
          role="button"
          aria-label="Clear templates search input"
          class="fa fa-times dropdown-input-clear js-dropdown-input-clear">
        </i>
      </div>
      <div class="dropdown-content"></div>
      <div class="dropdown-footer">
        <ul class="dropdown-footer-list">
          <li>
            <a class="no-template">
              No template
            </a>
          </li>
          <li>
            <a class="reset-template">
              Reset template
            </a>
          </li>
        </ul>
      </div>
    </div>
  </div>
</template>
