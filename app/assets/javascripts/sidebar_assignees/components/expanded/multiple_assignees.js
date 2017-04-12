export default {
  name: 'MultipleAssignees',
  data() {
    return {
      defaultRenderCount: 5,
      showLess: true,
    };
  },
  props: {
    rootPath: {
      type: String,
      required: true,
    },
    users: {
      type: Array,
      required: true,
    },
  },
  computed: {
    renderShowMoreSection() {
      return this.users.length > this.defaultRenderCount;
    },
    numberOfHiddenAssignees() {
      return this.users.length - this.defaultRenderCount;
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
      return !this.showLess || (index < this.defaultRenderCount && this.showLess);
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
          <div class="user-item" v-for="(user, index) in users"
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
