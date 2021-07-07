<script>
import { GlLoadingIcon, GlIcon } from '@gitlab/ui';
import { n__, __ } from '~/locale';

export default {
  name: 'AssigneeTitle',
  components: {
    GlLoadingIcon,
    GlIcon,
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
    showToggle: {
      type: Boolean,
      required: false,
      default: false,
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
  <div class="hide-collapsed gl-line-height-20 gl-mb-2 gl-text-gray-900">
    {{ assigneeTitle }}
    <gl-loading-icon v-if="loading" size="sm" inline class="align-bottom" />
    <a
      v-if="editable"
      class="js-sidebar-dropdown-toggle edit-link float-right"
      href="#"
      data-test-id="edit-link"
      data-track-event="click_edit_button"
      data-track-label="right_sidebar"
      data-track-property="assignee"
    >
      {{ titleCopy }}
    </a>
    <a
      v-if="showToggle"
      :aria-label="__('Toggle sidebar')"
      class="gutter-toggle float-right js-sidebar-toggle"
      href="#"
      role="button"
    >
      <gl-icon data-hidden="true" name="chevron-double-lg-right" :size="12" />
    </a>
  </div>
</template>
