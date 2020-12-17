<script>
import { GlFormCheckbox } from '@gitlab/ui';

export default {
  components: {
    GlFormCheckbox,
  },
  props: {
    currentBoard: {
      type: Object,
      required: true,
    },
    board: {
      type: Object,
      required: true,
    },
    isNewForm: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    const { hide_backlog_list: hideBacklogList, hide_closed_list: hideClosedList } = this.isNewForm
      ? this.board
      : this.currentBoard;

    return {
      hideClosedList,
      hideBacklogList,
    };
  },
  methods: {
    changeClosedList(checked) {
      this.board.hideClosedList = !checked;
    },
    changeBacklogList(checked) {
      this.board.hideBacklogList = !checked;
    },
  },
};
</script>

<template>
  <div class="gl-mb-5">
    <label class="label-bold gl-font-lg" for="board-new-name">
      {{ __('List options') }}
    </label>
    <p class="text-secondary gl-mb-3">
      {{ __('Configure which lists are shown for anyone who visits this board') }}
    </p>
    <gl-form-checkbox
      :checked="!hideBacklogList"
      data-testid="backlog-list-checkbox"
      @change="changeBacklogList"
      >{{ __('Show the Open list') }}
    </gl-form-checkbox>
    <gl-form-checkbox
      :checked="!hideClosedList"
      data-testid="closed-list-checkbox"
      @change="changeClosedList"
      >{{ __('Show the Closed list') }}
    </gl-form-checkbox>
  </div>
</template>
