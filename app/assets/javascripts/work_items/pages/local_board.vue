<script>
import { GlButton, GlFormSelect } from '@gitlab/ui';
import { __ } from '~/locale';
import { buildPools } from './object_pools';

function subtractArrays(arr1, arr2) {
  const setB = new Set(arr2);
  return arr1.filter((item) => !setB.has(item));
}

export default {
  name: 'LocalBoard',
  components: {
    GlButton,
    GlFormSelect,
  },
  props: {
    workItemListData: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      groupBy: 'label',
      hideEmpty: false,
    };
  },
  computed: {
    pools() {
      return buildPools(this.workItemListData);
    },
    groups() {
      switch (this.groupBy) {
        case 'label':
          return this.labelGroups().filter((g) => (this.hideEmpty ? g.items.length > 0 : true));
        case 'assignee':
          return this.assigneeGroups().filter((g) => (this.hideEmpty ? g.items.length > 0 : true));
        case 'author':
          return this.authorGroups().filter((g) => (this.hideEmpty ? g.items.length > 0 : true));
        case 'milestone':
          return this.milestoneGroups().filter((g) => (this.hideEmpty ? g.items.length > 0 : true));
        default:
          return [];
      }
    },
    items() {
      return this.pools.workItems;
    },
    itemIds() {
      return Object.values(this.items).map((i) => i.id);
    },
  },
  methods: {
    labelGroups() {
      const groups = [];
      const includedItemIds = [];
      for (const i of Object.values(this.pools.labels)) {
        groups.push({
          title: i.title,
          items: i.workItems,
        });
        includedItemIds.push(...i.workItems);
      }
      const noLabel = subtractArrays(this.itemIds, includedItemIds);
      return [{ title: __('No label'), items: noLabel }, ...groups];
    },
    assigneeGroups() {
      const groups = [];
      const includedItemIds = [];
      for (const i of Object.values(this.pools.users)) {
        groups.push({
          title: i.name,
          items: i.assigned,
        });
        includedItemIds.push(...i.assigned);
      }
      const noAssignee = subtractArrays(this.itemIds, includedItemIds);
      return [{ title: __('Unassigned'), items: noAssignee }, ...groups];
    },
    authorGroups() {
      const groups = [];
      const includedItemIds = [];
      for (const i of Object.values(this.pools.users)) {
        groups.push({
          title: i.name,
          items: i.authored,
        });
        includedItemIds.push(...i.authored);
      }
      const noAssignee = subtractArrays(this.itemIds, includedItemIds);
      return [{ title: __('No Author'), items: noAssignee }, ...groups];
    },
    milestoneGroups() {
      const groups = [];
      const includedItemIds = [];
      for (const i of Object.values(this.pools.milestones)) {
        groups.push({
          title: i.title,
          items: i.workItems,
        });
        includedItemIds.push(...i.workItems);
      }
      const noMilestone = subtractArrays(this.itemIds, includedItemIds);
      return [{ title: __('No Milestone'), items: noMilestone }, ...groups];
    },
  },
};
</script>

<template>
  <div class="gl-mt-4">
    <div class="gl-ml-4 gl-flex gl-gap-x-4">
      <div>
        <label for="group-by">{{ __('Group by') }} </label>
        <gl-form-select id="group-by" v-model="groupBy" name="group-by">
          <option value="label">{{ __('Label') }}</option>
          <option value="assignee">{{ __('Assignee') }}</option>
          <option value="author">{{ __('Author') }}</option>
          <option value="milestone">{{ __('Milestone') }}</option>
        </gl-form-select>
      </div>
      <gl-button @click="hideEmpty = !hideEmpty">
        {{ hideEmpty ? __('Show empty') : __('Hide empty') }}
      </gl-button>
      <gl-button class="gl-ml-auto" @click="$emit('back')">
        {{ __('Back') }}
      </gl-button>
    </div>
    <div class="gl-mt-6 gl-flex gl-w-full gl-flex-nowrap gl-overflow-x-scroll">
      <div v-for="(group, index) in groups" :key="index" class="gl-mx-4 gl-w-1/5">
        <p>{{ group.title }}</p>
        <ul class="gl-list-none gl-p-0">
          <li v-if="group.items.length === 0" class="p-2 gl-rounded gl-bg-strong gl-p-0">
            <p>
              {{ __('No items') }}
            </p>
          </li>
          <li v-for="id in group.items" :key="id" class="p-2 gl-rounded my-2 gl-bg-strong gl-p-0">
            <a :href="items[id].webUrl">{{ items[id].reference }}</a>
            <p>{{ items[id].title }}</p>
          </li>
        </ul>
      </div>
    </div>
  </div>
</template>
