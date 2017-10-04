<script>
/* global BoardService, MilestoneSelect */

import loadingIcon from '~/vue_shared/components/loading_icon.vue';
import extraMilestones from '../mixins/extra_milestones';

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
    defaultText: {
      type: String,
      required: true,
    },
    title: {
      type: String,
      required: true,
    },
    canEdit: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isOpen: false,
      loading: true,
      milestones: [],
      extraMilestones,
    };
  },
  components: {
    loadingIcon,
  },
  computed: {
    milestoneTitle() {
      return this.board.milestone ? this.board.milestone.title : '';
    },
  },
  methods: {
    selectMilestone(milestone) {
      this.$set(this.board, 'milestone', milestone);
    },
  },
  mounted() {
    new MilestoneSelect(null, this.$refs.dropdownButton, {
      handleClick: this.selectMilestone,
    });
  },
};
</script>

<template>
  <div class="block milestone">
    <div class="title append-bottom-10">
      Milestone
      <a
        v-if="canEdit"
        class="edit-link pull-right"
        href="#"
      >
        Edit
      </a>
    </div>
    <div class="value">
      <span
        class="no-value"
        v-if="!board.milestone"
      >
        None
      </span>
      <span
        class="bold has-tooltip"
        v-if="board.milestone"
      >
        {{ board.milestone.title }}
      </span>
    </div>
    <div
      class="selectbox"
      style="display: none;"
    >
      <input
        :value="board.milestone.id"
        name="milestone_id"
        type="hidden"
        v-if="board.milestone"
      >
      <div class="dropdown">
        <button
          ref="dropdownButton"
          :data-selected="milestoneTitle"
          class="dropdown-menu-toggle wide"
          :data-milestones="milestonePath"
          :data-show-no="true"
          :data-show-any="true"
          :data-show-started="true"
          :data-show-upcoming="true"
          data-toggle="dropdown"
          :data-use-id="true"
          type="button"
        >
          Milestone
          <i
            aria-hidden="true"
            data-hidden="true"
            class="fa fa-chevron-down"
          />
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
            >
            <i
              aria-hidden="true"
              data-hidden="true"
              class="fa fa-search dropdown-input-search"
            />
            <i
              role="button"
              aria-hidden="true"
              data-hidden="true"
              class="fa fa-times dropdown-input-clear js-dropdown-input-clear"
            />
          </div>
          <div class="dropdown-content" />
          <div class="dropdown-loading">
            <loading-icon />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
