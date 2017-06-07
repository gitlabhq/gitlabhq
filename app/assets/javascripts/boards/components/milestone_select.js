/* global BoardService */

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
    selectMilestone: {
      type: Function,
      required: true,
    },
  },
  data() {
    return {
      loading: false,
      milestones: [],
      extraMilestones,
    };
  },
  mounted() {
    BoardService.loadMilestones.call(this);
  },
  template: `
    <div>
      <div class="text-center">
        <i
          v-if="loading"
          class="fa fa-spinner fa-spin"></i>
      </div>
      <ul
        class="board-milestone-list"
        v-if="!loading">
        <li v-for="milestone in extraMilestones">
          <a
            href="#"
            @click.prevent.stop="selectMilestone(milestone)">
            <i
              class="fa fa-check"
              v-if="board.milestone_id === milestone.id"></i>
            {{ milestone.title }}
          </a>
        </li>
        <li class="divider"></li>
        <li v-for="milestone in milestones">
          <a
            href="#"
            @click.prevent.stop="selectMilestone(milestone)">
            <i
              class="fa fa-check"
              v-if="board.milestone_id === milestone.id"></i>
            {{ milestone.title }}
          </a>
        </li>
      </ul>
    </div>
  `,
};
