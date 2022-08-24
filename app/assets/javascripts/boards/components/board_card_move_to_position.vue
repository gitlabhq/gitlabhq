<script>
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { mapActions, mapGetters, mapState } from 'vuex';
import { s__ } from '~/locale';

import Tracking from '~/tracking';

export default {
  i18n: {
    moveToStartText: s__('Boards|Move to start of list'),
    moveToEndText: s__('Boards|Move to end of list'),
  },
  name: 'BoardCardMoveToPosition',
  components: {
    GlDropdown,
    GlDropdownItem,
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
  },
  computed: {
    ...mapState(['pageInfoByListId']),
    ...mapGetters(['getBoardItemsByList']),
    tracking() {
      return {
        category: 'boards:list',
        label: 'move_to_position',
        property: `type_card`,
      };
    },
    listItems() {
      return this.getBoardItemsByList(this.list.id);
    },
    listHasNextPage() {
      return this.pageInfoByListId[this.list.id]?.hasNextPage;
    },
    firstItemInListId() {
      return this.listItems[0]?.id;
    },
    lengthOfListItemsInBoard() {
      return this.listItems?.length;
    },
    lastItemInTheListId() {
      return this.listItems[this.lengthOfListItemsInBoard - 1]?.id;
    },
    itemIdentifier() {
      return `${this.item.id}-${this.item.iid}-${this.index}`;
    },
    showMoveToEndOfList() {
      return !this.listHasNextPage;
    },
    isFirstItemInList() {
      return this.index === 0;
    },
    isLastItemInList() {
      return this.index === this.lengthOfListItemsInBoard - 1;
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
      const moveAfterId = this.firstItemInListId;
      this.moveToPosition({
        moveAfterId,
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
      const moveBeforeId = this.lastItemInTheListId;
      this.moveToPosition({
        moveBeforeId,
      });
    },
    moveToPosition({ moveAfterId, moveBeforeId }) {
      this.moveItem({
        itemId: this.item.id,
        itemIid: this.item.iid,
        itemPath: this.item.referencePath,
        fromListId: this.list.id,
        toListId: this.list.id,
        moveAfterId,
        moveBeforeId,
      });
    },
  },
};
</script>

<template>
  <gl-dropdown
    ref="dropdown"
    :key="itemIdentifier"
    data-testid="move-card-dropdown"
    icon="ellipsis_v"
    :text="s__('Boards|Move card')"
    :text-sr-only="true"
    class="move-to-position gl-display-block gl-mb-2 gl-ml-2 gl-mt-n3 gl-mr-n3"
    category="tertiary"
    :tabindex="index"
    no-caret
    @keydown.esc.native="$emit('hide')"
  >
    <div>
      <gl-dropdown-item data-testid="action-move-to-first" @click.stop="moveToStart">
        {{ $options.i18n.moveToStartText }}
      </gl-dropdown-item>
      <gl-dropdown-item
        v-if="showMoveToEndOfList"
        data-testid="action-move-to-end"
        @click.stop="moveToEnd"
      >
        {{ $options.i18n.moveToEndText }}
      </gl-dropdown-item>
    </div>
  </gl-dropdown>
</template>
