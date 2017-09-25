<template>
  <div class="droplab-dropdown">
    <div class="media">
      <label class="media-body">Milestone</label>
      <a href="#" data-dropdown-trigger="#milestone-dropdown" ref="trigger">
        Edit
      </a>
    </div>
    <div>
      {{ board.milestone ? board.milestone.title : 'Milestone' }}
      <ul
        ref="list"
        class="dropdown-menu"
      >
        <li
          v-for="milestone in extraMilestones"
          :key="milestone.id"
        >
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
        <li
          v-for="milestone in milestones"
          :key="milestone.id"
        >
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
  </div>
</template>

<script>
/* global BoardService */

import DropLab from '~/droplab/drop_lab';
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

    this.droplab = new DropLab();
    this.droplab.init(this.$refs.trigger, this.$refs.list);
  },
};
</script>
