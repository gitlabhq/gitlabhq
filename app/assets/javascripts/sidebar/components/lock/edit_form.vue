<script>
import { GlSprintf } from '@gitlab/ui';
import editFormButtons from './edit_form_buttons.vue';

export default {
  components: {
    editFormButtons,
    GlSprintf,
  },
  props: {
    isLocked: {
      required: true,
      type: Boolean,
    },
    issuableDisplayName: {
      required: true,
      type: String,
    },
  },
};
</script>

<template>
  <div class="dropdown show">
    <div class="dropdown-menu sidebar-item-warning-message" data-testid="warning-text">
      <p v-if="isLocked" class="text">
        <gl-sprintf
          :message="
            __(
              'Unlock this %{issuableDisplayName}? %{strongStart}Everyone%{strongEnd} will be able to comment.',
            )
          "
        >
          <template #issuableDisplayName>{{ issuableDisplayName }}</template>
          <template #strong="{ content }"
            ><strong>{{ content }}</strong></template
          >
        </gl-sprintf>
      </p>

      <p v-else class="text">
        <gl-sprintf
          :message="
            __(
              'Lock this %{issuableDisplayName}? Only %{strongStart}project members%{strongEnd} will be able to comment.',
            )
          "
        >
          <template #issuableDisplayName>{{ issuableDisplayName }}</template>
          <template #strong="{ content }"
            ><strong>{{ content }}</strong></template
          >
        </gl-sprintf>
      </p>

      <edit-form-buttons :is-locked="isLocked" :issuable-display-name="issuableDisplayName" />
    </div>
  </div>
</template>
