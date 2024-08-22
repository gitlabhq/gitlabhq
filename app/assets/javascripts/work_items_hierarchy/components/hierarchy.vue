<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlIcon, GlBadge } from '@gitlab/ui';

export default {
  components: {
    GlIcon,
    GlBadge,
  },
  props: {
    workItemTypes: {
      type: Array,
      required: true,
    },
  },
  methods: {
    isLastItem(index, workItem) {
      const hasMoreThanOneItem = workItem.nestedTypes.length > 1;
      const isLastItemInArray = index === workItem.nestedTypes.length - 1;

      return isLastItemInArray && hasMoreThanOneItem;
    },
    nestedWorkItemTypeMargin(index, workItem) {
      const isLastItemInArray = index === workItem.nestedTypes.length - 1;
      const hasMoreThanOneItem = workItem.nestedTypes.length > 1;

      if (isLastItemInArray && hasMoreThanOneItem) {
        return 'gl-ml-0';
      }

      return 'gl-ml-6';
    },
  },
};
</script>
<template>
  <div>
    <div
      v-for="workItem in workItemTypes"
      :key="workItem.id"
      class="gl-mb-3"
      :class="{ flex: !workItem.available }"
    >
      <span
        class="gl-inline-flex gl-items-center gl-justify-center gl-rounded-base gl-border-1 gl-border-solid gl-border-gray-100 gl-pb-2 gl-pl-2 gl-pr-3 gl-pt-2 gl-leading-normal"
        data-testid="work-item-wrapper"
      >
        <span
          :style="{
            backgroundColor: workItem.backgroundColor,
            color: workItem.color,
          }"
          class="justify-content-center hierarchy-icon-wrapper gl-mr-2 gl-inline-flex gl-items-center gl-rounded-base"
        >
          <gl-icon :size="workItem.iconSize || 12" :name="workItem.icon" />
        </span>

        {{ workItem.title }}
      </span>

      <gl-badge
        v-if="!workItem.available"
        variant="info"
        icon="license"
        class="gl-ml-3 gl-self-center"
        >{{ workItem.license }}</gl-badge
      >

      <div v-if="workItem.nestedTypes" :class="{ 'gl-relative': workItem.nestedTypes.length > 1 }">
        <svg
          v-if="workItem.nestedTypes.length > 1"
          class="hierarchy-rounded-arrow-tail gl-text-gray-400"
          data-testid="hierarchy-rounded-arrow-tail"
          width="2"
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
        >
          <line
            x1="0.75"
            y1="1"
            x2="0.75"
            y2="100%"
            stroke="currentColor"
            stroke-width="1.5"
            stroke-linecap="round"
          />
        </svg>
        <template v-for="(nestedWorkItem, index) in workItem.nestedTypes">
          <div :key="nestedWorkItem.id" class="gl-ml-6 gl-mt-2 gl-block">
            <gl-icon name="arrow-down" class="gl-text-gray-400" />
          </div>
          <gl-icon
            v-if="isLastItem(index, workItem)"
            :key="nestedWorkItem.id"
            name="level-up"
            class="hierarchy-rounded-arrow gl-ml-2 gl-text-gray-400"
          />
          <span
            :key="nestedWorkItem.id"
            class="gl-mt-2 gl-inline-flex gl-items-center gl-justify-center gl-rounded-base gl-border-1 gl-border-solid gl-border-gray-100 gl-pb-2 gl-pl-2 gl-pr-3 gl-pt-2 gl-leading-normal"
            :class="nestedWorkItemTypeMargin(index, workItem)"
          >
            <span
              :style="{
                backgroundColor: nestedWorkItem.backgroundColor,
                color: nestedWorkItem.color,
              }"
              class="justify-content-center hierarchy-icon-wrapper gl-mr-2 gl-inline-flex gl-items-center gl-rounded-base"
            >
              <gl-icon :size="nestedWorkItem.iconSize || 12" :name="nestedWorkItem.icon" />
            </span>

            {{ nestedWorkItem.title }}
          </span>
        </template>
      </div>
    </div>
  </div>
</template>
