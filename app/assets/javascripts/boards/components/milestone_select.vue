<template>
  <div>
    <gl-dropdown>
      <template slot="items">
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
        <li
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
      </template>
    </gl-dropdown>
  </div>
</template>

<script>
/* global BoardService */

import DropLab from '~/droplab/drop_lab';
import GlDropdown from './dropdown.vue';
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
  components: {
    GlDropdown,
  },
  mounted() {
    BoardService.loadMilestones.call(this);
  },
};
</script>
