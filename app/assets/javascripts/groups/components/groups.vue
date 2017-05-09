<script>
import GroupsStore from '../stores/groups_store';
import GroupsService from '../services/groups_service';
import GroupItem from '../components/group_item.vue';
import GroupItemProxy from '../components/group_item_proxy.vue';
import eventHub from '../event_hub';

export default {
  components: {
    'group-item': GroupItem,
    // 'group-item-proxy': GroupItemProxy,
  },

  data() {
    const store = new GroupsStore();

    return {
      store,
      state: store.state,
    };
  },

  created() {
    const appEl = document.querySelector('#dashboard-group-app');

    this.service = new GroupsService(appEl.dataset.endpoint);
    this.fetchGroups();

    eventHub.$on('toggleSubGroups', this.toggleSubGroups);
  },

  methods: {
    fetchGroups(group = null) {
      this.service.getGroups()
        .then((response) => {
          this.store.setGroups(group, this.service.getFakeGroups());
        })
        .catch(() => {
          // TODO: Handler error
        });
    },
    toggleSubGroups(group) {
      GroupsStore.toggleSubGroups(group);

      this.fetchGroups(group);
    },
  },
  render(createElement) {
    const ref = [];

    if (!this.state.groups) {
      return createElement('div', 'hola mundo');
    }

    function iterator (groups, ref) {
      for (let i = 0; i < groups.length; i += 1) {
        ref.push(createElement('group-item', {
          props: {
            group: groups[i],
          },
        }));

        if (groups[i].subGroups && groups[i].isOpen) {
          iterator(groups[i].subGroups, ref);
        }
      }
    }

    iterator(this.state.groups, ref);

    return createElement('table', {
      class: {
        table: true, 
        'table-bordered': true,
      },
      props: {
      }
    }, [createElement('tbody', {}, ref)]);
  },
};
</script>
