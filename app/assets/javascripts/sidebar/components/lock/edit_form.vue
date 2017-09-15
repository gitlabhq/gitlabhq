<script>
import editFormButtons from './edit_form_buttons.vue';
import issuableMixin from '../../../vue_shared/mixins/issuable';

export default {
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

    issuableType: {
      required: true,
      type: String,
    },
  },

  mixins: [
    issuableMixin,
  ],

  components: {
    editFormButtons,
  },
};
</script>

<template>
  <div class="dropdown open">
    <div class="dropdown-menu sidebar-item-warning-message">
      <p class="text" v-if="isLocked">
        {{ __(`Unlock this ${issuableDisplayName(issuableType)}?`) }}
        <strong>{{ __('Everyone') }}</strong>
        {{ __('will be able to comment.') }}
      </p>

      <p class="text" v-else>
        {{ __(`Lock this ${issuableDisplayName(issuableType)}? Only`) }}
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
</template>
