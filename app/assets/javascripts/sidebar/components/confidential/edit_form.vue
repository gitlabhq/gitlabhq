<script>
import { GlSprintf } from '@gitlab/ui';
import editFormButtons from './edit_form_buttons.vue';
import { __ } from '../../../locale';

export default {
  components: {
    editFormButtons,
    GlSprintf,
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
      return __(
        'You are going to turn on the confidentiality. This means that only team members with %{strongStart}at least Reporter access%{strongEnd} are able to see and leave comments on the %{issuableType}.',
      );
    },
    confidentialityOffWarning() {
      return __(
        'You are going to turn off the confidentiality. This means %{strongStart}everyone%{strongEnd} will be able to see and leave a comment on this %{issuableType}.',
      );
    },
  },
};
</script>

<template>
  <div class="dropdown show">
    <div class="dropdown-menu sidebar-item-warning-message">
      <div>
        <p v-if="!confidential">
          <gl-sprintf :message="confidentialityOnWarning">
            <template #strong="{ content }">
              <strong>{{ content }}</strong>
            </template>
            <template #issuableType>{{ issuableType }}</template>
          </gl-sprintf>
        </p>
        <p v-else>
          <gl-sprintf :message="confidentialityOffWarning">
            <template #strong="{ content }">
              <strong>{{ content }}</strong>
            </template>
            <template #issuableType>{{ issuableType }}</template>
          </gl-sprintf>
        </p>
        <edit-form-buttons :full-path="fullPath" :confidential="confidential" />
      </div>
    </div>
  </div>
</template>
