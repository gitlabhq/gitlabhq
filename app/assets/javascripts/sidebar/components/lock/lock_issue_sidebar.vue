<script>
/* global Flash */
import editForm from './edit_form.vue';
import issuableMixin from '../../../vue_shared/mixins/issuable';

export default {
  props: {
    isLocked: {
      required: true,
      type: Boolean,
    },

    isEditable: {
      required: true,
      type: Boolean,
    },

    mediator: {
      required: true,
      type: Object,
      validator(mediatorObject) {
        return mediatorObject.service && mediatorObject.service.update && mediatorObject.store;
      },
    },

    issuableType: {
      required: true,
      type: String,
    },
  },

  mixins: [
    issuableMixin,
  ],

  components: {
    editForm,
  },

  computed: {
    lockIconClass() {
      return this.isLocked ? 'fa-lock' : 'fa-unlock';
    },

    isLockDialogOpen() {
      return this.mediator.store.isLockDialogOpen;
    },
  },

  methods: {
    toggleForm() {
      this.mediator.store.isLockDialogOpen = !this.mediator.store.isLockDialogOpen;
    },

    updateLockedAttribute(locked) {
      this.mediator.service.update(this.issuableType, {
        discussion_locked: locked,
      })
      .then(() => location.reload())
      .catch(() => Flash(this.__(`Something went wrong trying to change the locked state of this ${this.issuableDisplayName(this.issuableType)}`)));
    },
  },
};
</script>

<template>
  <div class="block issuable-sidebar-item lock">
    <div class="sidebar-collapsed-icon">
      <i
        class="fa"
        :class="lockIconClass"
        aria-hidden="true"
      ></i>
    </div>

    <div class="title hide-collapsed">
      Lock {{issuableDisplayName(issuableType) }}
      <button
        v-if="isEditable"
        class="pull-right lock-edit btn btn-blank"
        type="button"
        @click.prevent="toggleForm"
      >
        {{ __('Edit') }}
      </button>
    </div>

    <div class="value sidebar-item-value hide-collapsed">
      <edit-form
        v-if="isLockDialogOpen"
        :toggle-form="toggleForm"
        :is-locked="isLocked"
        :update-locked-attribute="updateLockedAttribute"
        :issuable-type="issuableType"
      />

      <div
        v-if="isLocked"
        class="value sidebar-item-value"
      >
        <i
          aria-hidden="true"
          class="fa fa-lock sidebar-item-icon is-active"
        ></i>
        {{ __('Locked') }}
      </div>

      <div
        v-else
        class="no-value sidebar-item-value hide-collapsed"
      >
        <i
          aria-hidden="true"
          class="fa fa-unlock sidebar-item-icon"
        ></i>
        {{ __('Unlocked') }}
      </div>
    </div>
  </div>
</template>
