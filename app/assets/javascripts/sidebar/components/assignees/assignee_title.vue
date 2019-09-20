<script>
import { n__ } from '~/locale';
import { trackEvent } from 'ee_else_ce/event_tracking/issue_sidebar';

export default {
  name: 'AssigneeTitle',
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
  },
  computed: {
    assigneeTitle() {
      const assignees = this.numberOfAssignees;
      return n__('Assignee', `%d Assignees`, assignees);
    },
  },
  methods: {
    trackEdit() {
      trackEvent('click_edit_button', 'assignee');
    },
  },
};
</script>
<template>
  <div class="title hide-collapsed">
    {{ assigneeTitle }}
    <i v-if="loading" aria-hidden="true" class="fa fa-spinner fa-spin block-loading"></i>
    <a
      v-if="editable"
      class="js-sidebar-dropdown-toggle edit-link float-right"
      href="#"
      @click.prevent="trackEdit"
    >
      {{ __('Edit') }}
    </a>
    <a
      v-if="showToggle"
      :aria-label="__('Toggle sidebar')"
      class="gutter-toggle float-right js-sidebar-toggle"
      href="#"
      role="button"
    >
      <i aria-hidden="true" data-hidden="true" class="fa fa-angle-double-right"></i>
    </a>
  </div>
</template>
