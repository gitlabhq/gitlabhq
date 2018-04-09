<script>
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
      return assignees > 1 ? `${assignees} Assignees` : 'Assignee';
    },
  },
};
</script>
<template>
  <div class="title hide-collapsed">
    {{ assigneeTitle }}
    <i
      v-if="loading"
      aria-hidden="true"
      class="fa fa-spinner fa-spin block-loading"
    >

    </i>
    <a
      v-if="editable"
      class="js-sidebar-dropdown-toggle edit-link float-right"
      href="#"
    >
      {{ __('Edit') }}
    </a>
    <a
      v-if="showToggle"
      aria-label="Toggle sidebar"
      class="gutter-toggle float-right js-sidebar-toggle"
      href="#"
      role="button"
    >
      <i
        aria-hidden="true"
        data-hidden="true"
        class="fa fa-angle-double-right"
      >
      </i>
    </a>
  </div>
</template>
