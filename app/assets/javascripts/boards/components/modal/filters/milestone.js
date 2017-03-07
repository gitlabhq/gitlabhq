/* eslint-disable no-new */
/* global Vue */
/* global MilestoneSelect */
module.exports = Vue.extend({
  name: 'filter-milestone',
  props: {
    milestonePath: {
      type: String,
      required: true,
    },
  },
  mounted() {
    new MilestoneSelect(null, this.$refs.dropdown);
  },
  template: `
    <div class="dropdown">
      <button
        class="dropdown-menu-toggle js-milestone-select"
        type="button"
        data-toggle="dropdown"
        data-show-any="true"
        data-show-upcoming="true"
        data-field-name="milestone_title"
        :data-milestones="milestonePath"
        ref="dropdown">
        <span class="dropdown-toggle-text">
          Milestone
        </span>
        <i class="fa fa-chevron-down"></i>
      </button>
      <div class="dropdown-menu dropdown-select dropdown-menu-selectable dropdown-menu-milestone">
        <div class="dropdown-title">
          <span>Filter by milestone</span>
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
            placeholder="Search milestones"
            autocomplete="off" />
          <i class="fa fa-search dropdown-input-search"></i>
          <i role="button" class="fa fa-times dropdown-input-clear js-dropdown-input-clear"></i>
        </div>
        <div class="dropdown-content"></div>
        <div class="dropdown-loading"><i class="fa fa-spinner fa-spin"></i></div>
      </div>
    </div>
  `,
});
