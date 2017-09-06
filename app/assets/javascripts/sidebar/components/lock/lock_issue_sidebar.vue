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
      isEditing: false,
    };
  },

  computed: {
    lockIconClass() {
      return this.isLocked ? 'fa-lock' : 'fa-unlock';
    },
  },

  methods: {
    toggleForm() {
      this.isEditing = !this.isEditing;
    },

    updateLockedAttribute(locked) {
      this.service.update('issue', {
        discussion_locked: locked,
      })
      .then(() => location.reload())
      .catch(() => Flash(this.__('Something went wrong trying to change the locked state of this issue')));
    },
  },
};
</script>

<template>
  <div class="block issuable-sidebar-item">
    <div class="sidebar-collapsed-icon">
      <i class="fa" :class="lockIconClass" aria-hidden="true" data-hidden="true"></i>
    </div>

    <div class="title hide-collapsed">
      {{ __('Lock issue') }}
      <a
        v-if="isEditable"
        class="pull-right lock-edit"
        href="#"
        @click.prevent="toggleForm"
      >
        {{ __('Edit') }}
      </a>
    </div>

    <div class="value sidebar-item-value hide-collapsed">
      <editForm
        v-if="isEditing"
        :toggle-form="toggleForm"
        :is-locked="isLocked"
        :update-locked-attribute="updateLockedAttribute"
      />

      <div v-if="isLocked" class="value sidebar-item-value">
        <i class="fa fa-lock is-active"></i>
        {{ __('Locked') }}
      </div>

      <div v-else class="no-value sidebar-item-value hide-collapsed">
        <i aria-hidden="true" data-hidden="true" class="fa fa-unlock is-not-active"></i>
        {{ __('Unlocked') }}
      </div>
    </div>
  </div>
</template>
