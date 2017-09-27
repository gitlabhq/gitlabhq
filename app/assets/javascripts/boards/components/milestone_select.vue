<template>
  <div class="dropdown-menu dropdown-menu-wide">
    <div class="dropdown-input">
      <input
        class="dropdown-input-field"
        type="search"
        placeholder="Search milestones">
      <i aria-hidden="true" data-hidden="true" class="fa fa-search dropdown-input-search"></i>
    </div>
    <ul
      ref="list"
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
            v-if="false"></i>
          {{ milestone.title }}
        </a>
      </li>
      <li class="divider"></li>
      <li v-if="loading">
        <loading-icon />
      </li>
      <li
        v-else
        v-for="milestone in milestones"
        :key="milestone.id"
      >
        <a
          href="#"
          @click.prevent.stop="selectMilestone(milestone)">
          <i
            class="fa fa-check"
            v-if="false"></i>
          {{ milestone.title }}
        </a>
      </li>
    </ul>
  </div>
</template>

<script>
/* global BoardService */

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
    value: {
      type: String,
      required: false,
    },
  },
  components: {
    loadingIcon,
  },
  data() {
    return {
      loading: true,
      milestones: [],
      extraMilestones,
    };
  },
  mounted() {
    BoardService.loadMilestones.call(this).then(() => this.loading = false);
  },
  methods: {
    selectMilestone(milestone) {
      this.board.milestone_id = milestone.id;
      this.$emit('input', milestone);
    },
  },
};
</script>
