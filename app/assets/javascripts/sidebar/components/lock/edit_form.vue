<script>
import editFormButtons from './edit_form_buttons.vue';

export default {
  components: {
    editFormButtons,
  },

  props: {
    isLocked: {
      required: true,
      type: Boolean,
    },

    toggleForm: {
      required: true,
      type: Function,
    },

    updateLockedAttribute: {
      required: true,
      type: Function,
    },
  },
};
</script>

<template>
  <div class="dropdown open">
    <div class="dropdown-menu sidebar-item-warning-message">
      <div>
        <p v-if="isLocked">
          {{ __('Unlock this issue?') }}
          <strong>{{ __('Everyone') }}</strong>
          {{ __('will be able to comment.') }}
        </p>

        <p v-else>
          {{ __('Lock this issue? Only') }}
          <strong>{{ __('project members') }}</strong>
          {{ __('will be able to comment.') }}
        </p>

        <edit-form-buttons
          :is-locked="isLocked"
          :toggle-form="toggleForm"
          :update-locked-attribute="updateLockedAttribute"
        />
      </div>
    </div>
  </div>
</template>
