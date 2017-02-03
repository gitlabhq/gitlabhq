/* global Vue */
(() => {
  gl.issueBoards.BoardMilestoneSelect = Vue.extend({
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
        <ul v-if="!loading">
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
})();
