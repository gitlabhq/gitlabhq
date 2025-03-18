<script>
import { GlButton, GlFormSelect } from '@gitlab/ui';
import { __ } from '~/locale';
import {
  buildPools,
  getGroupOptions,
  getPoolNameForGrouping,
  groupBy,
} from 'ee_else_ce/work_items/pages/object_pools';

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
      const poolName = getPoolNameForGrouping(this.groupBy);
      const options = {
        pool: this.pools[poolName],
        itemIds: this.itemIds,
        hideEmpty: this.hideEmpty,
        noneLabel: __('None'),
      };
      if (this.groupBy === 'assignee') {
        options.itemsProperty = 'assigned';
      }
      if (this.groupBy === 'author') {
        options.itemsProperty = 'authored';
      }
      return groupBy(options);
    },
    groupOptions() {
      return getGroupOptions();
    },
    items() {
      return this.pools.workItems;
    },
    itemIds() {
      return Object.values(this.items).map((i) => i.id);
    },
  },
};
</script>

<template>
  <div class="gl-mt-4">
    <div class="gl-ml-4 gl-flex gl-gap-x-4">
      <div>
        <label for="group-by">{{ s__('WorkItem|Group by') }} </label>
        <gl-form-select id="group-by" v-model="groupBy" name="group-by">
          <option v-for="option in groupOptions" :key="option.value" :value="option.value">
            {{ option.label }}
          </option>
        </gl-form-select>
      </div>
      <gl-button @click="hideEmpty = !hideEmpty">
        {{ hideEmpty ? s__('WorkItem|Show empty') : s__('WorkItem|Hide empty') }}
      </gl-button>
      <gl-button class="gl-ml-auto" @click="$emit('back')">
        {{ s__('WorkItem|Back') }}
      </gl-button>
    </div>
    <div class="gl-mt-6 gl-flex gl-w-full gl-flex-nowrap gl-overflow-x-scroll">
      <div v-for="(group, index) in groups" :key="index" class="gl-mx-4 gl-w-1/5">
        <p>{{ group.title }}</p>
        <ul class="gl-list-none gl-p-0">
          <li v-if="group.items.length === 0" class="p-2 gl-rounded gl-bg-strong gl-p-0">
            <p>
              {{ s__('WorkItem|No items') }}
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
