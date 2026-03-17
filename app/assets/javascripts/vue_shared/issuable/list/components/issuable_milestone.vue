<script>
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import WorkItemAttribute from '~/vue_shared/components/work_item_attribute.vue';

export default {
  name: 'IssuableMilestone',
  components: {
    WorkItemAttribute,
  },
  props: {
    milestone: {
      type: Object,
      required: true,
    },
  },
  computed: {
    milestoneLink() {
      return this.milestone.webPath || this.milestone.webUrl;
    },
    popoverAttributes() {
      return {
        'data-reference-type': 'milestone',
        'data-placement': 'top',
        'data-milestone': getIdFromGraphQLId(this.milestone.id),
      };
    },
  },
};
</script>

<template>
  <work-item-attribute
    anchor-id="issuable-milestone"
    :title="milestone.title"
    wrapper-component="a"
    wrapper-component-class="!gl-text-subtle gl-bg-transparent gl-border-0 gl-p-0 focus-visible:gl-focus-inset gl-max-w-30 gl-min-w-0 has-popover"
    icon-name="milestone"
    :icon-size="12"
    :is-link="true"
    :href="milestoneLink"
    :popover-attributes="popoverAttributes"
  />
</template>
