<script>
  import MilestoneSelect from '~/milestone_select';

  const ANY_MILESTONE = 'Any Milestone';
  const NO_MILESTONE = 'No Milestone';

  export default {
    props: {
      board: {
        type: Object,
        required: true,
      },
      milestonePath: {
        type: String,
        required: true,
      },
      canEdit: {
        type: Boolean,
        required: false,
        default: false,
      },
    },

    computed: {
      milestoneTitle() {
        if (this.noMilestone) return NO_MILESTONE;
        return this.board.milestone ? this.board.milestone.title : ANY_MILESTONE;
      },
      noMilestone() {
        return this.milestoneId === 0;
      },
      milestoneId() {
        return this.board.milestone_id;
      },
      milestoneTitleClass() {
        return this.milestoneTitle === ANY_MILESTONE ? 'text-secondary' : 'bold';
      },
      selected() {
        if (this.noMilestone) return NO_MILESTONE;
        return this.board.milestone ? this.board.milestone.name : '';
      },
    },
    mounted() {
      this.milestoneDropdown = new MilestoneSelect(null, this.$refs.dropdownButton, {
        handleClick: this.selectMilestone,
      });
    },
    methods: {
      selectMilestone(milestone) {
        let { id } = milestone;
        // swap the IDs of 'Any' and 'No' milestone to what backend requires
        if (milestone.title === ANY_MILESTONE) {
          id = -1;
        } else if (milestone.title === NO_MILESTONE) {
          id = 0;
        }
        this.board.milestone_id = id;
        this.board.milestone = {
          ...milestone,
          id,
        };
      },
    },
  };
</script>

<template>
  <div class="block milestone">
    <div class="title append-bottom-10">
      Milestone
      <button
        v-if="canEdit"
        type="button"
        class="edit-link btn btn-blank float-right"
      >
        Edit
      </button>
    </div>
    <div
      :class="milestoneTitleClass"
      class="value"
    >
      {{ milestoneTitle }}
    </div>
    <div
      class="selectbox"
      style="display: none;"
    >
      <input
        :value="milestoneId"
        name="milestone_id"
        type="hidden"
      />
      <div class="dropdown">
        <button
          ref="dropdownButton"
          :data-selected="selected"
          :data-milestones="milestonePath"
          :data-show-no="true"
          :data-show-any="true"
          :data-show-started="true"
          :data-show-upcoming="true"
          :data-use-id="true"
          class="dropdown-menu-toggle wide"
          data-toggle="dropdown"
          type="button"
        >
          Milestone
          <i
            aria-hidden="true"
            data-hidden="true"
            class="fa fa-chevron-down"
          >
          </i>
        </button>
        <div class="dropdown-menu dropdown-select dropdown-menu-selectable">
          <div
            class="dropdown-input"
          >
            <input
              type="search"
              class="dropdown-input-field"
              placeholder="Search milestones"
              autocomplete="off"
            />
            <i
              aria-hidden="true"
              data-hidden="true"
              class="fa fa-search dropdown-input-search"
            >
            </i>
            <i
              role="button"
              aria-hidden="true"
              data-hidden="true"
              class="fa fa-times dropdown-input-clear js-dropdown-input-clear"
            >
            </i>
          </div>
          <div class="dropdown-content">
          </div>
          <div class="dropdown-loading">
            <gl-loading-icon />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
