/* global Vue */
module.exports = Vue.extend({
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
      anyMilestone: {
        id: null,
        title: 'Any Milestone',
      },
    };
  },
  mounted() {
    this.loading = true;
    this.$http.get(this.milestonePath)
      .then((res) => {
        this.milestones = res.json();
        this.loading = false;
      });
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
        <li>
          <a
            href="#"
            @click.prevent.stop="selectMilestone(anyMilestone)">
            <i
              class="fa fa-check"
              v-if="board.milestone_id === anyMilestone.id"></i>
            {{ anyMilestone.title }}
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
});
