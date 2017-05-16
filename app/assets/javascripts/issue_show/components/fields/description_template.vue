<script>
  export default {
    props: {
      issuableTemplates: {
        type: Array,
        required: false,
        default: () => [],
      },
    },
    mounted() {
      return new gl.IssuableTemplateSelectors();
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
      :data-data="JSON.stringify(issuableTemplates)"
      data-field-name="issuable_template"
      data-selected="null"
      data-project-path="gitlab-ce"
      data-namespace-path="gitlab-org"
      data-toggle="dropdown">
      <span class="dropdown-toggle-text ">
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
          aria-hidden="true"
          class="fa fa-times dropdown-input-clear js-dropdown-input-clear">
        </i>
      </div>
      <div class="dropdown-content ">
      </div>
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
