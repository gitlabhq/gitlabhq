<script>
import WorkItemAttribute from '~/vue_shared/components/work_item_attribute.vue';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { __, sprintf } from '~/locale';

export default {
  components: {
    WorkItemAttribute,
  },
  mixins: [timeagoMixin],
  props: {
    milestone: {
      type: Object,
      required: true,
    },
  },
  computed: {
    popoverAttributes() {
      return {
        'data-reference-type': 'milestone',
        'data-placement': 'top',
        'data-milestone': getIdFromGraphQLId(this.milestone.id),
      };
    },
  },
  methods: {
    createAriaLabel() {
      return sprintf(__(`Milestone: %{milestoneTitle}`), {
        milestoneTitle: this.milestone.title,
      });
    },
  },
};
</script>
<template>
  <work-item-attribute
    anchor-id="board-card-milestone"
    wrapper-component="button"
    wrapper-component-class="issue-milestone-details gl-flex gl-max-w-15 gl-gap-2 gl-items-center !gl-cursor-help gl-bg-transparent gl-border-0 gl-p-0 gl-text-subtle focus-visible:gl-focus-inset has-popover"
    icon-name="milestone"
    icon-class="!gl-shrink-0 gl-text-subtle"
    :title="milestone.title"
    title-component-class="milestone-title gl-inline-block gl-truncate"
    :aria-label="createAriaLabel()"
    :popover-attributes="popoverAttributes"
  >
    {{ milestone.title }}
  </work-item-attribute>
</template>
