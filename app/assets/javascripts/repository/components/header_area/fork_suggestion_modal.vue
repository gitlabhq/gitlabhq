<script>
import { GlModal } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: {
    GlModal,
  },
  props: {
    visible: {
      type: Boolean,
      required: true,
    },
    forkPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    primaryAction() {
      return {
        text: __('Fork'),
        attributes: {
          variant: 'confirm',
          href: this.forkPath,
          class: 'gl-w-full sm:gl-w-auto',
          'data-method': 'post',
          'data-testid': 'fork',
        },
      };
    },
    secondaryAction() {
      return {
        text: __('Cancel'),
        attributes: {
          class: 'gl-w-full sm:gl-w-auto',
          'data-testid': 'cancel',
        },
      };
    },
  },
};
</script>

<template>
  <gl-modal
    ref="forkSuggestionModal"
    modal-id="fork-suggestion-modal"
    no-focus-on-show
    :visible="visible"
    :title="__('Fork to make changes')"
    :action-primary="primaryAction"
    :action-secondary="secondaryAction"
    v-on="$listeners"
  >
    <p data-testid="message">
      {{
        __(
          "You're not allowed to make changes to this project directly. Create a fork to make changes and submit a merge request.",
        )
      }}
    </p>
  </gl-modal>
</template>
