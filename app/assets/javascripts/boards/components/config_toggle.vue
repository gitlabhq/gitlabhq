<script>
import { GlButton, GlModalDirective } from '@gitlab/ui';
import { formType } from '~/boards/constants';
import { s__ } from '~/locale';
import Tracking from '~/tracking';

export default {
  components: {
    GlButton,
  },
  directives: {
    GlModalDirective,
  },
  mixins: [Tracking.mixin()],
  inject: ['canAdminList'],
  computed: {
    buttonText() {
      return this.canAdminList ? s__('Boards|Edit board') : s__('Boards|View scope');
    },
  },
  methods: {
    showPage() {
      this.track('click_button', { label: 'edit_board' });
      this.$emit('showBoardModal', formType.edit);
    },
  },
};
</script>

<template>
  <div class="gl-ml-3 gl-display-flex gl-align-items-center">
    <gl-button
      v-gl-modal-directive="'board-config-modal'"
      data-testid="boards-config-button"
      @click.prevent="showPage"
    >
      {{ buttonText }}
    </gl-button>
  </div>
</template>
