<script>
import ActionButtonGroup from './action_button_group.vue';
import RemoveGroupLinkButton from './remove_group_link_button.vue';

export default {
  name: 'GroupActionButtons',
  components: { ActionButtonGroup, RemoveGroupLinkButton },
  props: {
    member: {
      type: Object,
      required: true,
    },
    permissions: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <action-button-group>
    <div v-if="permissions.canRemove" class="gl-px-1">
      <remove-group-link-button :group-link="member" />
    </div>
  </action-button-group>
</template>
