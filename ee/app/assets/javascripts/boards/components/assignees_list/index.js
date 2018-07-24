import Vue from 'vue';
import _ from 'underscore';
import { __ } from '~/locale';
import Flash from '~/flash';
import axios from '~/lib/utils/axios_utils';

import AssigneesListContainer from './assignees_list_container.vue';

export default Vue.extend({
  components: {
    AssigneesListContainer,
  },
  props: {
    listAssigneesPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      loading: true,
      store: gl.issueBoards.BoardsStore,
    };
  },
  mounted() {
    this.loadAssignees();
  },
  methods: {
    loadAssignees() {
      if (this.store.state.assignees.length) {
        return Promise.resolve();
      }

      return axios
        .get(this.listAssigneesPath)
        .then(({ data }) => {
          this.loading = false;
          this.store.state.assignees = data;
        })
        .catch(() => {
          this.loading = false;
          Flash(__('Something went wrong while fetching assignees list'));
        });
    },
    handleItemClick(assignee) {
      if (!this.store.findList('title', assignee.name)) {
        this.store.new({
          title: assignee.name,
          position: this.store.state.lists.length - 2,
          list_type: 'assignee',
          user: assignee,
        });

        this.store.state.lists = _.sortBy(this.store.state.lists, 'position');
      }
    },
  },
  render(createElement) {
    return createElement('assignees-list-container', {
      props: {
        loading: this.loading,
        assignees: this.store.state.assignees,
      },
      on: {
        onItemSelect: this.handleItemClick,
      },
    });
  },
});
