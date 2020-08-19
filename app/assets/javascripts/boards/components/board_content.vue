<script>
import BoardContentLayout from '~/boards/components/board_content_layout.vue';
import BoardColumn from '~/boards/components/board_column.vue';

export default {
  components: {
    BoardContentLayout,
    BoardColumn,
  },
};
</script>

<template>
  <board-content-layout v-bind="$attrs">
    <template
      #board-content-decoration="{ lists, canAdminList, groupId, disabled, issueLinkBase, rootPath, boardId }"
    >
      <board-column
        v-for="list in lists"
        :key="list.id"
        ref="board"
        :can-admin-list="canAdminList"
        :group-id="groupId"
        :list="list"
        :disabled="disabled"
        :issue-link-base="issueLinkBase"
        :root-path="rootPath"
        :board-id="boardId"
      />
    </template>
  </board-content-layout>
</template>
