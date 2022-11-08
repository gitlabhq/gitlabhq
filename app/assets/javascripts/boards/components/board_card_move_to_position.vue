<script>
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { mapActions, mapState } from 'vuex';
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
  },
};
</script>

<template>
  <gl-dropdown
    ref="dropdown"
    :key="itemIdentifier"
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
      <gl-dropdown-item @click.stop="moveToStart">
        {{ $options.i18n.moveToStartText }}
      </gl-dropdown-item>
      <gl-dropdown-item @click.stop="moveToEnd">
        {{ $options.i18n.moveToEndText }}
      </gl-dropdown-item>
    </div>
  </gl-dropdown>
</template>
