<script>
/* global Flash */
import editForm from './edit_form.vue';

export default {
  components: {
    editForm,
  },

  props: {
    isLocked: {
      required: true,
      type: Boolean,
    },

    isEditable: {
      required: true,
      type: Boolean,
    },

    service: {
      required: true,
      type: Object,
    },
  },

  data() {
    return {
      edit: false,
    };
  },

  computed: {
    faLock() {
      const lock = this.isLocked ? 'fa-lock' : 'fa-unlock';

      return {
        [lock]: true,
      };
    },
  },

  methods: {
    toggleForm() {
      this.edit = !this.edit;
    },

    updateLockedAttribute(locked) {
      this.service.update('issue', {
        discussion_locked: locked,
      })
      .then(() => location.reload())
      .catch(() => new Flash('Something went wrong trying to change the locked state of this issue'));
    },
  },
};
</script>

<template>
  <div class="block issuable-sidebar-item">
    <div class="sidebar-collapsed-icon">
      <i class="fa" :class="faLock" aria-hidden="true" data-hidden="true"></i>
    </div>

    <div class="title hide-collapsed">
      Lock issue
      <a
        v-if="isEditable"
        class="pull-right"
        href="#"
        @click.prevent="toggleForm"
      >
        Edit
      </a>
    </div>

    <div class="value sidebar-item-value hide-collapsed">
      <editForm
        v-if="edit"
        :toggle-form="toggleForm"
        :is-locked="isLocked"
        :update-locked-attribute="updateLockedAttribute"
      />

      <div v-if="isLocked" class="value sidebar-item-value">
        <i class="fa fa-lock is-active"></i>
        Locked
      </div>

      <div v-else class="no-value sidebar-item-value hide-collapsed">
        <i aria-hidden="true" data-hidden="true" class="fa fa-unlock is-not-active"></i>
        Unlocked
      </div>
    </div>
  </div>
</template>
