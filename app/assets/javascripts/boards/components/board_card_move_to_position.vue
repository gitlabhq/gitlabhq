<script>
import { GlDisclosureDropdown } from '@gitlab/ui';
import { mapActions, mapState } from 'vuex';
import Tracking from '~/tracking';
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
    ...mapState(['pageInfoByListId']),
    tracking() {
      return {
        category: 'boards:list',
        label: 'move_to_position',
        property: `type_card`,
      };
    },
    listHasNextPage() {
      return this.pageInfoByListId[this.list.id]?.hasNextPage;
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
    ...mapActions(['moveItem']),
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
      this.moveItem({
        itemId: this.item.id,
        itemIid: this.item.iid,
        itemPath: this.item.referencePath,
        fromListId: this.list.id,
        toListId: this.list.id,
        positionInList,
        atIndex: this.index,
        allItemsLoadedInList: !this.listHasNextPage,
      });
    },
    selectMoveAction({ text }) {
      if (text === BOARD_CARD_MOVE_TO_POSITIONS_START_OPTION) {
        this.moveToStart();
      } else {
        this.moveToEnd();
      }
    },
  },
};
</script>

<template>
  <gl-disclosure-dropdown
    ref="dropdown"
    :key="itemIdentifier"
    class="move-to-position gl-display-block gl-mb-2 gl-ml-auto gl-mt-n3 gl-mr-n3 js-no-trigger"
    category="tertiary"
    :items="$options.BOARD_CARD_MOVE_TO_POSITIONS_OPTIONS"
    icon="ellipsis_v"
    :tabindex="index"
    :toggle-text="s__('Boards|Move card')"
    :text-sr-only="true"
    no-caret
    data-testid="board-move-to-position"
    @action="selectMoveAction"
  />
</template>
