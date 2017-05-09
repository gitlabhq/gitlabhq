<script>
import GroupItem from './group_item.vue';

export default {
  name: 'group-item-proxy',
  props: {
    groups: {
      type: Array,
      required: true,
    },
  },
  components: {
    'group-item': GroupItem,
  },
  render(createElement) {
    const groupItemsComponents = []

    for (let i = 0; i < this.groups.length; i += 1) {
      groupItemsComponents.push(createElement('group-item', {
        props: {
          group: this.groups[i],
        }
      }));

      if (this.groups[i].subgroups && this.groups[i].isOpen) {
        groupItemsComponents.push(createElement('group-item-proxy', {
          props: {
            groups: this.groups[i].subgroups,
          }
        }));
      }
    }

    return createElement('tr', {
    }, groupItemsComponents);
  },
};
</script>