import Vue from 'vue';
import _ from 'underscore';
import { __, sprintf } from '~/locale';
import Flash from '~/flash';
import axios from '~/lib/utils/axios_utils';

import ListContainer from './list_container.vue';

export default Vue.extend({
  components: {
    ListContainer,
  },
  props: {
    listPath: {
      type: String,
      required: true,
    },
    listType: {
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
    this.loadList();
  },
  methods: {
    loadList() {
      if (this.store.state[this.listType].length) {
        return Promise.resolve();
      }

      return axios
        .get(this.listPath)
        .then(({ data }) => {
          this.loading = false;
          this.store.state[this.listType] = data;
        })
        .catch(() => {
          this.loading = false;
          Flash(sprintf(__('Something went wrong while fetching %{listType} list'), {
            listType: this.listType,
          }));
        });
    },
    filterItems(term, items) {
      const query = term.toLowerCase();

      return items.filter((item) => {
        const name = item.name ? item.name.toLowerCase() : item.title.toLowerCase();
        const foundName = name.indexOf(query) > -1;

        if (this.listType === 'milestones') {
          return foundName;
        }

        const username = item.username.toLowerCase();
        return foundName || username.indexOf(query) > -1;
      });
    },
    handleItemClick(item) {
      if (!this.store.findList('title', item.name)) {
        const list = {
          title: item.name,
          position: this.store.state.lists.length - 2,
          list_type: this.listType,
        };

        if (this.listType === 'milestones') {
          list.milestone = item;
        } else if (this.listType === 'assignees') {
          list.user = item;
        }

        this.store.new(list);

        this.store.state.lists = _.sortBy(this.store.state.lists, 'position');
      }
    },
  },
  render(createElement) {
    return createElement('list-container', {
      props: {
        loading: this.loading,
        items: this.store.state[this.listType],
        listType: this.listType,
      },
      on: {
        onItemSelect: this.handleItemClick,
      },
    });
  },
});
