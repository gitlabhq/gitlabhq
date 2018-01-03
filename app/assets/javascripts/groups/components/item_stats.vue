<script>
import tooltip from '../../vue_shared/directives/tooltip';
import { ITEM_TYPE, VISIBILITY_TYPE_ICON, GROUP_VISIBILITY_TYPE, PROJECT_VISIBILITY_TYPE } from '../constants';

export default {
  directives: {
    tooltip,
  },
  props: {
    item: {
      type: Object,
      required: true,
    },
  },
  computed: {
    visibilityIcon() {
      return VISIBILITY_TYPE_ICON[this.item.visibility];
    },
    visibilityTooltip() {
      if (this.item.type === ITEM_TYPE.GROUP) {
        return GROUP_VISIBILITY_TYPE[this.item.visibility];
      }
      return PROJECT_VISIBILITY_TYPE[this.item.visibility];
    },
    isProject() {
      return this.item.type === ITEM_TYPE.PROJECT;
    },
    isGroup() {
      return this.item.type === ITEM_TYPE.GROUP;
    },
  },
};
</script>

<template>
  <div class="stats">
    <span
      v-tooltip
      v-if="isGroup"
      :title="s__('Subgroups')"
      class="number-subgroups"
      data-placement="top"
      data-container="body">
      <i
        class="fa fa-folder"
        aria-hidden="true"
      />
      {{item.subgroupCount}}
    </span>
    <span
      v-tooltip
      v-if="isGroup"
      :title="s__('Projects')"
      class="number-projects"
      data-placement="top"
      data-container="body">
      <i
        class="fa fa-bookmark"
        aria-hidden="true"
      />
      {{item.projectCount}}
    </span>
    <span
      v-tooltip
      v-if="isGroup"
      :title="s__('Members')"
      class="number-users"
      data-placement="top"
      data-container="body">
      <i
        class="fa fa-users"
        aria-hidden="true"
      />
      {{item.memberCount}}
    </span>
    <span
      v-if="isProject"
      class="project-stars">
      <i
        class="fa fa-star"
        aria-hidden="true"
      />
      {{item.starCount}}
    </span>
    <span
      v-tooltip
      :title="visibilityTooltip"
      data-placement="left"
      data-container="body"
      class="item-visibility">
      <i
        :class="visibilityIcon"
        class="fa"
        aria-hidden="true"
      />
    </span>
  </div>
</template>
