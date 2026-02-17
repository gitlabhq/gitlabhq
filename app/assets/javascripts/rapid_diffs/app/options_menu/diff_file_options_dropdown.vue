<script>
import {
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlDisclosureDropdownGroup,
  GlSprintf,
} from '@gitlab/ui';
import { sprintf, __ } from '~/locale';
import { copyToClipboard } from '~/lib/utils/copy_to_clipboard';
import { withLinkedFileUrlParams } from '~/rapid_diffs/utils/linked_file';
import toast from '~/vue_shared/plugins/global_toast';

export default {
  name: 'DiffFileOptionsMenu',
  components: {
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    GlDisclosureDropdownGroup,
    GlSprintf,
  },
  props: {
    items: {
      type: Array,
      required: true,
    },
    fileId: {
      type: String,
      required: true,
    },
    oldPath: {
      type: String,
      required: true,
    },
    newPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    allItems() {
      return [
        {
          text: __('Copy link to the file'),
          action: this.onFileLinkCopyClick,
        },
        ...this.items,
      ];
    },
  },
  async mounted() {
    // We need to refocus the toggle because the original toggle is replaced with this component
    // In Vue 3, we need to wait for child components to fully render before accessing their DOM
    await this.$nextTick();
    this.hydrateDropdown();
  },
  methods: {
    hydrateDropdown() {
      const toggle = this.$el.querySelector('button');
      if (!toggle) return;
      toggle.focus();
      // .focus() initiates additional transition which we don't need
      toggle.style.transition = 'none';
      requestAnimationFrame(() => {
        toggle.style.transition = '';
      });
    },
    transformMessage(item) {
      if (!item.messageData) return item.text;
      return sprintf(item.text, item.messageData);
    },
    // eslint-disable-next-line vue/no-unused-properties -- public method
    closeAndFocus() {
      this.$refs.dropdown.closeAndFocus();
    },
    onFileLinkCopyClick() {
      const url = withLinkedFileUrlParams(new URL(window.location), {
        oldPath: this.oldPath,
        newPath: this.newPath,
        fileId: this.fileId,
      });
      copyToClipboard(url);
      toast(__('Link to diff file copied.'));
    },
  },
};
</script>

<template>
  <gl-disclosure-dropdown
    ref="dropdown"
    data-options-toggle
    placement="right"
    icon="ellipsis_v"
    start-opened
    no-caret
    category="tertiary"
    size="small"
    :toggle-text="s__('RapidDiffs|Show options')"
    text-sr-only
  >
    <template v-for="(dropdownItem, index) in allItems">
      <template v-if="dropdownItem.items">
        <gl-disclosure-dropdown-group
          :key="index"
          :group="dropdownItem"
          :bordered="dropdownItem.bordered"
        >
          <template #list-item="{ item }">
            <gl-sprintf :message="transformMessage(item)">
              <template #code="{ content }">
                <code v-text="content"></code>
              </template>
            </gl-sprintf>
          </template>
        </gl-disclosure-dropdown-group>
      </template>
      <template v-else>
        <gl-disclosure-dropdown-item :key="index" :item="dropdownItem">
          <template #list-item>
            <gl-sprintf :message="transformMessage(dropdownItem)">
              <template #code="{ content }">
                <code v-text="content"></code>
              </template>
            </gl-sprintf>
          </template>
        </gl-disclosure-dropdown-item>
      </template>
    </template>
  </gl-disclosure-dropdown>
</template>
