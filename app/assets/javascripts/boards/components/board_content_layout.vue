<script>
export default {
  props: {
    lists: {
      type: Array,
      required: true,
    },
    canAdminList: {
      type: Boolean,
      required: true,
    },
    groupId: {
      type: Number,
      required: false,
      default: null,
    },
    disabled: {
      type: Boolean,
      required: true,
    },
    issueLinkBase: {
      type: String,
      required: true,
    },
    rootPath: {
      type: String,
      required: true,
    },
    boardId: {
      type: String,
      required: true,
    },
    isSwimlanesOff: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
};
</script>

<template>
  <div
    :class="{ 'boards-list gl-w-full gl-py-5 gl-px-3 gl-white-space-nowrap': isSwimlanesOff }"
    data-qa-selector="boards_list"
    data-testid="boards_list"
  >
    <slot name="board-content-decoration" v-bind="$props"></slot>
  </div>
</template>
