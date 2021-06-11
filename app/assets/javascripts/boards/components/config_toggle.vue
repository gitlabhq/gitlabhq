<script>
import { GlButton, GlModalDirective, GlTooltipDirective } from '@gitlab/ui';
import { formType } from '~/boards/constants';
import eventHub from '~/boards/eventhub';
import { s__, __ } from '~/locale';
import Tracking from '~/tracking';

export default {
  components: {
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    GlModalDirective,
  },
  mixins: [Tracking.mixin()],
  props: {
    boardsStore: {
      type: Object,
      required: false,
      default: null,
    },
    canAdminList: {
      type: Boolean,
      required: true,
    },
    hasScope: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    buttonText() {
      return this.canAdminList ? s__('Boards|Edit board') : s__('Boards|View scope');
    },
    tooltipTitle() {
      return this.hasScope ? __("This board's scope is reduced") : '';
    },
  },
  methods: {
    showPage() {
      this.track('click_button', { label: 'edit_board' });
      eventHub.$emit('showBoardModal', formType.edit);
      if (this.boardsStore) {
        this.boardsStore.showPage(formType.edit);
      }
    },
  },
};
</script>

<template>
  <div class="gl-ml-3 gl-display-flex gl-align-items-center">
    <gl-button
      v-gl-modal-directive="'board-config-modal'"
      v-gl-tooltip
      :title="tooltipTitle"
      :class="{ 'dot-highlight': hasScope }"
      data-qa-selector="boards_config_button"
      @click.prevent="showPage"
    >
      {{ buttonText }}
    </gl-button>
  </div>
</template>
