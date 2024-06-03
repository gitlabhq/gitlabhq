<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { n__, __ } from '~/locale';

export default {
  name: 'AssigneeTitle',
  components: {
    GlLoadingIcon,
  },
  props: {
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
    numberOfAssignees: {
      type: Number,
      required: true,
    },
    editable: {
      type: Boolean,
      required: true,
    },
    changing: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    assigneeTitle() {
      const assignees = this.numberOfAssignees;
      return n__('Assignee', `%d Assignees`, assignees);
    },
    titleCopy() {
      return this.changing ? __('Apply') : __('Edit');
    },
  },
};
</script>
<template>
  <div class="hide-collapsed gl-leading-20 gl-mb-2 gl-text-gray-900 gl-font-bold">
    {{ assigneeTitle }}
    <gl-loading-icon v-if="loading" size="sm" inline class="align-bottom" />
    <a
      v-if="editable"
      class="js-sidebar-dropdown-toggle edit-link btn gl-text-gray-900! gl-ml-auto hide-collapsed btn-default btn-sm gl-button btn-default-tertiary gl-float-right"
      href="#"
      data-test-id="edit-link"
      data-track-action="click_edit_button"
      data-track-label="right_sidebar"
      data-track-property="assignee"
    >
      {{ titleCopy }}
    </a>
  </div>
</template>
