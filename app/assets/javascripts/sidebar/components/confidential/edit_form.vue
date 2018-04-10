<script>
import editFormButtons from './edit_form_buttons.vue';
import { s__ } from '../../../locale';

export default {
  components: {
    editFormButtons,
  },
  props: {
    isConfidential: {
      required: true,
      type: Boolean,
    },
    updateConfidentialAttribute: {
      required: true,
      type: Function,
    },
  },
  computed: {
    confidentialityOnWarning() {
      return s__(
        'confidentiality|You are going to turn on the confidentiality. This means that only team members with <strong>at least Reporter access</strong> are able to see and leave comments on the issue.',
      );
    },
    confidentialityOffWarning() {
      return s__(
        'confidentiality|You are going to turn off the confidentiality. This means <strong>everyone</strong> will be able to see and leave a comment on this issue.',
      );
    },
  },
};
</script>

<template>
  <div class="dropdown open">
    <div class="dropdown-menu sidebar-item-warning-message">
      <div>
        <p
          v-if="!isConfidential"
          v-html="confidentialityOnWarning">
        </p>
        <p
          v-else
          v-html="confidentialityOffWarning">
        </p>
        <edit-form-buttons
          :is-confidential="isConfidential"
          :update-confidential-attribute="updateConfidentialAttribute"
        />
      </div>
    </div>
  </div>
</template>
