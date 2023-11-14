<script>
import { GlSprintf } from '@gitlab/ui';
import EditFormButtons from './edit_form_buttons.vue';

export default {
  components: {
    EditFormButtons,
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
              'Unlock this discussion? %{strongStart}Everyone%{strongEnd} will be able to comment.',
            )
          "
        >
          <template #strong="{ content }"
            ><strong>{{ content }}</strong></template
          >
        </gl-sprintf>
      </p>

      <p v-else class="text">
        <gl-sprintf
          :message="
            __(
              'Lock this discussion? Only %{strongStart}project members%{strongEnd} will be able to comment.',
            )
          "
        >
          <template #strong="{ content }"
            ><strong>{{ content }}</strong></template
          >
        </gl-sprintf>
      </p>

      <edit-form-buttons :is-locked="isLocked" :issuable-display-name="issuableDisplayName" />
    </div>
  </div>
</template>
