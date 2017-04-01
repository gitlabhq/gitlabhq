export default {
  name: 'MultipleAssignees',
  data() {
    return {
      showLess: true,
    };
  },
  props: {
    assignees: {
      type: Object,
      required: true
    },
  },
  computed: {
    rootPath() {
      return this.assignees.rootPath;
    },
    renderShowMoreSection() {
      return this.assignees.users.length > this.assignees.defaultRenderCount;
    },
    numberOfHiddenAssignees() {
      return this.assignees.users.length - this.assignees.defaultRenderCount;
    },
    isHiddenAssignees() {
      return this.numberOfHiddenAssignees > 0;
    },
  },
  methods: {
    toggleShowLess() {
      this.showLess = !this.showLess;
    },
    renderAssignee(index) {
      return !this.showLess || (index < this.assignees.defaultRenderCount && this.showLess);
    },
    assigneeUrl(username) {
      return `${this.rootPath}${username}`;
    },
    assigneeAlt(name) {
      return `${name}'s avatar`;
    },
  },
  template: `
    <div class="hide-collapsed">
      <div class="hide-collapsed">
        <div class="user-list">
          <div class="user-item" v-for="(user, index) in assignees.users"
              v-if="renderAssignee(index)" >
            <a class="user-link has-tooltip"
              data-placement="bottom"
              :href="assigneeUrl(user.username)"
              :data-title="user.name" >
              <img width="32"
                class="avatar avatar-inline s32"
                :alt="assigneeAlt(user.name)"
                :src="user.avatarUrl" >
            </a>
          </div>
        </div>
        <div class="user-list-more" v-if="renderShowMoreSection">
          <button type="button" class="btn-link" @click="toggleShowLess">
            <template v-if="showLess">
              + {{numberOfHiddenAssignees}} more
            </template>
            <template v-else>
              - show less
            </template>
          </button>
        </div>
      </div>
    </div>
  `,
};
