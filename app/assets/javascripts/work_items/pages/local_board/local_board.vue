<script>
import { GlButton, GlFormSelect } from '@gitlab/ui';
import { __ } from '~/locale';
import {
  buildPools,
  getGroupOptions,
  getPoolNameForGrouping,
  groupBy,
} from 'ee_else_ce/work_items/pages/local_board/object_pools';
import BoardCard from './board_card.vue';

export default {
  name: 'LocalBoard',
  components: {
    GlButton,
    GlFormSelect,
    BoardCard,
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
    <div class="gl-flex gl-h-[calc(100vh-60px-48px)] gl-min-h-0 gl-grow gl-flex-col">
      <div
        class="gl-min-h-0 gl-w-full gl-grow gl-overflow-x-auto gl-whitespace-nowrap gl-py-5 gl-pl-0 gl-pr-5 xl:gl-pl-3 xl:gl-pr-6"
      >
        <div
          v-for="(group, index) in groups"
          :key="index"
          class="gl-inline-flex gl-h-full gl-align-top"
        >
          <div
            class="gl-relative gl-inline-block gl-h-full gl-w-[400px] gl-whitespace-normal gl-px-3 gl-align-top"
          >
            <div
              class="gl-relative gl-flex gl-h-full gl-flex-col gl-rounded-base gl-bg-strong dark:gl-bg-subtle"
            >
              <header class="gl-relative">
                <h3 class="gl-m-0 gl-flex gl-h-9 gl-items-center gl-px-3 gl-text-base">
                  <span class="gl-grow gl-truncate gl-p-1">
                    {{ group.title }}
                  </span>
                </h3>
              </header>
              <div class="gl-relative gl-flex gl-h-full gl-min-h-0 gl-flex-col">
                <ul
                  class="gl-mb-0 gl-h-full gl-w-full gl-list-none gl-overflow-x-hidden gl-p-3 gl-pt-2"
                >
                  <li v-if="group.items.length === 0" class="p-2 gl-rounded gl-bg-strong gl-p-0">
                    <p>
                      {{ s__('WorkItem|No items') }}
                    </p>
                  </li>
                  <board-card v-for="id in group.items" :key="id" :item="items[id]" />
                </ul>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
