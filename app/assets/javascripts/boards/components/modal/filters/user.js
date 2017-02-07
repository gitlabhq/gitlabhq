/* eslint-disable no-new */
/* global Vue */
/* global UsersSelect */
module.exports = Vue.extend({
  name: 'filter-user',
  props: {
    toggleClassName: {
      type: String,
      required: true,
    },
    dropdownClassName: {
      type: String,
      required: false,
      default: '',
    },
    toggleLabel: {
      type: String,
      required: true,
    },
    fieldName: {
      type: String,
      required: true,
    },
    nullUser: {
      type: Boolean,
      required: false,
      default: false,
    },
    projectId: {
      type: Number,
      required: true,
    },
  },
  mounted() {
    new UsersSelect(null, this.$refs.dropdown);
  },
  computed: {
    currentUsername() {
      return gon.current_username;
    },
    dropdownTitle() {
      return `Filter by ${this.toggleLabel.toLowerCase()}`;
    },
    inputPlaceholder() {
      return `Search ${this.toggleLabel.toLowerCase()}`;
    },
  },
  template: `
    <div class="dropdown">
      <button
        class="dropdown-menu-toggle js-user-search"
        :class="toggleClassName"
        type="button"
        data-toggle="dropdown"
        data-current-user="true"
        :data-any-user="'Any ' + toggleLabel"
        :data-null-user="nullUser"
        :data-field-name="fieldName"
        :data-project-id="projectId"
        :data-first-user="currentUsername"
        ref="dropdown">
        <span class="dropdown-toggle-text">
          {{ toggleLabel }}
        </span>
        <i class="fa fa-chevron-down"></i>
      </button>
      <div
        class="dropdown-menu dropdown-select dropdown-menu-user dropdown-menu-selectable"
        :class="dropdownClassName">
        <div class="dropdown-title">
          {{ dropdownTitle }}
          <button
            class="dropdown-title-button dropdown-menu-close"
            aria-label="Close"
            type="button">
            <i class="fa fa-times dropdown-menu-close-icon"></i>
          </button>
        </div>
        <div class="dropdown-input">
          <input
            type="search"
            class="dropdown-input-field"
            autocomplete="off"
            :placeholder="inputPlaceholder" />
          <i class="fa fa-search dropdown-input-search"></i>
          <i
            role="button"
            class="fa fa-times dropdown-input-clear js-dropdown-input-clear">
          </i>
        </div>
        <div class="dropdown-content"></div>
        <div class="dropdown-loading"><i class="fa fa-spinner fa-spin"></i></div>
      </div>
    </div>
  `,
});
