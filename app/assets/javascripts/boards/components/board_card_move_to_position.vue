<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import { mapActions, mapState } from 'vuex';
import Tracking from '~/tracking';
import { BOARD_CARD_MOVE_TO_POSITION_OPTIONS, MOVE_TO_START } from '../constants';

export default {
  BOARD_CARD_MOVE_TO_POSITION_OPTIONS,
  name: 'BoardCardMoveToPosition',
  components: {
    GlCollapsibleListbox,
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
    selectMoveAction(action) {
      if (action === MOVE_TO_START) {
        this.moveToStart();
      } else {
        this.moveToEnd();
      }
    },
  },
};
</script>

<template>
  <gl-collapsible-listbox
    ref="dropdown"
    :key="itemIdentifier"
    category="tertiary"
    class="move-to-position gl-display-block gl-mb-2 gl-ml-2 gl-mt-n3 gl-mr-n3 js-no-trigger"
    icon="ellipsis_v"
    :items="$options.BOARD_CARD_MOVE_TO_POSITION_OPTIONS"
    no-caret
    :tabindex="index"
    :text-sr-only="true"
    :toggle-text="s__('Boards|Move card')"
    @keydown.esc.native="$emit('hide')"
    @select="selectMoveAction"
  />
</template>
