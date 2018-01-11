<script>
<<<<<<< HEAD
  import { s__ } from '~/locale';
  import tooltip from '~/vue_shared/directives/tooltip';
  import icon from '~/vue_shared/components/icon.vue';
  import modal from '~/vue_shared/components/modal.vue';
  import eventHub from '../event_hub';
  import { COMMON_STR } from '../constants';

  export default {
    components: {
      icon,
      modal,
=======
import tooltip from '~/vue_shared/directives/tooltip';
import icon from '~/vue_shared/components/icon.vue';
import eventHub from '../event_hub';
import { COMMON_STR } from '../constants';

export default {
  components: {
    icon,
  },
  directives: {
    tooltip,
  },
  props: {
    parentGroup: {
      type: Object,
      required: false,
      default: () => ({}),
>>>>>>> upstream/master
    },
    directives: {
      tooltip,
    },
<<<<<<< HEAD
    props: {
      parentGroup: {
        type: Object,
        required: false,
        default: () => ({}),
      },
      group: {
        type: Object,
        required: true,
      },
=======
  },
  computed: {
    leaveBtnTitle() {
      return COMMON_STR.LEAVE_BTN_TITLE;
>>>>>>> upstream/master
    },
    data() {
      return {
        modalStatus: false,
      };
    },
<<<<<<< HEAD
    computed: {
      leaveBtnTitle() {
        return COMMON_STR.LEAVE_BTN_TITLE;
      },
      editBtnTitle() {
        return COMMON_STR.EDIT_BTN_TITLE;
      },
      leaveConfirmationMessage() {
        return s__(`GroupsTree|Are you sure you want to leave the "${this.group.fullName}" group?`);
      },
    },
    methods: {
      onLeaveGroup() {
        this.modalStatus = true;
      },
      leaveGroup() {
        this.modalStatus = false;
        eventHub.$emit('leaveGroup', this.group, this.parentGroup);
      },
    },
  };
=======
  },
  methods: {
    onLeaveGroup() {
      eventHub.$emit('showLeaveGroupModal', this.group, this.parentGroup);
    },
  },
};
>>>>>>> upstream/master
</script>

<template>
  <div class="controls">
    <a
      v-tooltip
      v-if="group.canEdit"
      :href="group.editPath"
      :title="editBtnTitle"
      :aria-label="editBtnTitle"
      data-container="body"
      data-placement="bottom"
      class="edit-group btn no-expand">
      <icon name="settings"/>
    </a>
    <a
      v-tooltip
      v-if="group.canLeave"
      @click.prevent="onLeaveGroup"
      :href="group.leavePath"
      :title="leaveBtnTitle"
      :aria-label="leaveBtnTitle"
      data-container="body"
      data-placement="bottom"
      class="leave-group btn no-expand">
      <icon name="leave"/>
    </a>
  </div>
</template>
