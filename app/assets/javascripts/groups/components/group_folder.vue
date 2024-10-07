<script>
import { GlIcon } from '@gitlab/ui';
import { n__ } from '~/locale';
import { MAX_CHILDREN_COUNT } from '../constants';

export default {
  components: {
    GlIcon,
  },
  props: {
    parentGroup: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    groups: {
      type: Array,
      required: true,
    },
    action: {
      type: String,
      required: false,
      default: '',
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
  <ul class="groups-list group-list-tree gl-m-0 gl-flex gl-flex-col">
    <!-- eslint-disable-next-line vue/no-undef-components -->
    <group-item
      v-for="(group, index) in groups"
      :key="index"
      :group="group"
      :parent-group="parentGroup"
      :action="action"
    />
    <li v-if="hasMoreChildren" class="group-row">
      <a :href="parentGroup.relativePath" class="group-row-contents has-more-items gl-py-3">
        <gl-icon name="external-link" /> {{ moreChildrenStats }}
      </a>
    </li>
  </ul>
</template>
