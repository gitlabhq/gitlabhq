<script>
import { GlDisclosureDropdown, GlTooltipDirective } from '@gitlab/ui';
import Tracking from '~/tracking';
import { s__ } from '~/locale';
import {
  BOARD_CARD_MOVE_TO_POSITIONS_OPTIONS,
  BOARD_CARD_MOVE_TO_POSITIONS_START_OPTION,
} from '../constants';

export default {
  BOARD_CARD_MOVE_TO_POSITIONS_OPTIONS,
  name: 'BoardCardMoveToPosition',
  components: {
    GlDisclosureDropdown,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [Tracking.mixin()],
  props: {
    item: {
      type: Object,
      required: true,
      validator: (item) => ['id', 'iid', 'referencePath'].every((key) => item[key]),
    },
    list: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    index: {
      type: Number,
      required: true,
    },
    listItemsLength: {
      type: Number,
      required: true,
    },
  },
  computed: {
    tracking() {
      return {
        category: 'boards:list',
        label: 'move_to_position',
        property: `type_card`,
      };
    },
    itemIdentifier() {
      return `${this.item.id}-${this.item.iid}-${this.index}`;
    },
    isFirstItemInList() {
      return this.index === 0;
    },
    isLastItemInList() {
      return this.index === this.listItemsLength - 1;
    },
  },
  methods: {
    moveToStart() {
      this.track('click_toggle_button', {
        label: 'move_to_start',
      });
      /** in case it is the first in the list don't call any action/mutation * */
      if (this.isFirstItemInList) {
        return;
      }
      this.moveToPosition({
        positionInList: 0,
      });
    },
    moveToEnd() {
      this.track('click_toggle_button', {
        label: 'move_to_end',
      });
      /** in case it is the last in the list don't call any action/mutation * */
      if (this.isLastItemInList) {
        return;
      }
      this.moveToPosition({
        positionInList: -1,
      });
    },
    moveToPosition({ positionInList }) {
      this.$emit('moveToPosition', positionInList);
    },
    selectMoveAction({ text }) {
      if (text === BOARD_CARD_MOVE_TO_POSITIONS_START_OPTION) {
        this.moveToStart();
      } else {
        this.moveToEnd();
      }
    },
  },
  i18n: {
    moveCardText: s__('Boards|Card options'),
  },
};
</script>

<template>
  <gl-disclosure-dropdown
    ref="dropdown"
    :key="itemIdentifier"
    v-gl-tooltip.hover.focus.top="{
      title: $options.i18n.moveCardText,
      boundary: 'viewport',
    }"
    class="move-to-position js-no-trigger gl-absolute gl-right-3 gl-top-3 gl-block"
    size="small"
    category="tertiary"
    :items="$options.BOARD_CARD_MOVE_TO_POSITIONS_OPTIONS"
    icon="ellipsis_v"
    :aria-label="$options.i18n.moveCardText"
    :text-sr-only="true"
    no-caret
    data-testid="board-move-to-position"
    @action="selectMoveAction"
  />
</template>
