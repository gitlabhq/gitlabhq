import ShowMoreAssignees from './show_more_assignees';

export default {
  name: 'MultipleAssignees',
  data() {
    return {
      showMore: false,
    };
  },
  props: {
    assignees: { type: Object, required: true },
  },
  computed: {
    rootPath() {
      return this.assignees.rootPath;
    },
    shouldShowMoreAssignees() {
      return this.assignees.users.length > 5;
    },
    numberOfHiddenAssignees() {
      return this.showMore ? 0 : this.assignees.users.length - 5;
    },
    toggleShowMore() {
      return function toggleShowMore() {
        this.showMore = !this.showMore;
      }.bind(this);
    },
  },
  components: {
    'show-more-assignees': ShowMoreAssignees,
  },
  template: `
    <div class="hide-collapsed">
      <div class="hide-collapsed">
        <div class="user-list">
          <div class="user-item" v-for="(user, index) in assignees.users"
              v-if="showMore || (index < 5 && !showMore)" >
            <a class="user-link has-tooltip"
              data-placement="bottom"
              :href="rootPath + user.username"
              :data-title="user.name" >
              <img width="32"
                class="avatar avatar-inline s32"
                :alt="user.name + '\\'s avatar'"
                :src="user.avatarUrl" >
            </a>
          </div>
        </div>
        <show-more-assignees v-if="shouldShowMoreAssignees"
          :hiddenAssignees="numberOfHiddenAssignees"
          :toggle="toggleShowMore" />
      </div>
    </div>
  `,
};
