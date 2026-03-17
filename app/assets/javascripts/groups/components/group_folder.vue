<script>
import { GlIcon } from '@gitlab/ui';
import { n__ } from '~/locale';

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
    totalChildrenCount() {
      return this.parentGroup.childrenCount ?? 0;
    },
    currentChildrenCount() {
      return this.parentGroup.children?.length ?? 0;
    },
    hasMoreChildren() {
      return this.totalChildrenCount > this.currentChildrenCount;
    },
    moreChildrenStats() {
      return n__(
        'One more item',
        '%d more items',
        this.totalChildrenCount - this.currentChildrenCount,
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
