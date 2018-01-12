<script>
import { n__ } from '../../locale';
import { MAX_CHILDREN_COUNT } from '../constants';

export default {
  props: {
    parentGroup: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    groups: {
      type: Array,
      required: false,
      default: () => ([]),
    },
  },
  computed: {
    hasMoreChildren() {
      return this.parentGroup.childrenCount > MAX_CHILDREN_COUNT;
    },
    moreChildrenStats() {
      return n__(
        'One more item',
        '%d more items',
        this.parentGroup.childrenCount - this.parentGroup.children.length,
      );
    },
  },
};
</script>

<template>
  <ul class="content-list group-list-tree">
    <group-item
      v-for="(group, index) in groups"
      :key="index"
      :group="group"
      :parent-group="parentGroup"
    />
    <li
      v-if="hasMoreChildren"
      class="group-row">
      <a
        :href="parentGroup.relativePath"
        class="group-row-contents has-more-items">
        <i
          class="fa fa-external-link"
          aria-hidden="true"
        >
        </i>
        {{ moreChildrenStats }}
      </a>
    </li>
  </ul>
</template>
