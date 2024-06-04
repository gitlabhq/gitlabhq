<script>
import { GlButton, GlModalDirective, GlTooltipDirective } from '@gitlab/ui';
import { formType } from '~/boards/constants';
import { s__ } from '~/locale';
import Tracking from '~/tracking';

export default {
  components: {
    GlButton,
  },
  directives: {
    GlModalDirective,
    GlTooltipDirective,
  },
  mixins: [Tracking.mixin()],
  inject: ['canAdminList'],
  computed: {
    buttonText() {
      return this.canAdminList ? s__('Boards|Configure board') : s__('Boards|Board configuration');
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
  <gl-button
    v-gl-modal-directive="'board-config-modal'"
    v-gl-tooltip-directive
    data-testid="boards-config-button"
    icon="settings"
    :title="buttonText"
    category="tertiary"
    @click.prevent="showPage"
  />
</template>
