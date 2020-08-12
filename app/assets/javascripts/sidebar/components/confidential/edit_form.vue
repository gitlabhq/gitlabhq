<script>
import editFormButtons from './edit_form_buttons.vue';
import { __, sprintf } from '../../../locale';

export default {
  components: {
    editFormButtons,
  },
  props: {
    confidential: {
      required: true,
      type: Boolean,
    },
    fullPath: {
      required: true,
      type: String,
    },
    issuableType: {
      required: true,
      type: String,
    },
  },
  computed: {
    confidentialityOnWarning() {
      const accessLevel = __('at least Reporter access');

      return sprintf(
        __(
          'You are going to turn on the confidentiality. This means that only team members with %{accessLevel} are able to see and leave comments on the %{issuableType}.',
        ),
        { issuableType: this.issuableType, accessLevel: `<strong>${accessLevel}</strong>` },
        false,
      );
    },
    confidentialityOffWarning() {
      const accessLevel = __('everyone');

      return sprintf(
        __(
          'You are going to turn off the confidentiality. This means %{accessLevel} will be able to see and leave a comment on this %{issuableType}.',
        ),
        { issuableType: this.issuableType, accessLevel: `<strong>${accessLevel}</strong>` },
        false,
      );
    },
  },
};
</script>

<template>
  <div class="dropdown show">
    <div class="dropdown-menu sidebar-item-warning-message">
      <div>
        <p v-if="!confidential" v-html="confidentialityOnWarning"></p>
        <p v-else v-html="confidentialityOffWarning"></p>
        <edit-form-buttons :full-path="fullPath" :confidential="confidential" />
      </div>
    </div>
  </div>
</template>
