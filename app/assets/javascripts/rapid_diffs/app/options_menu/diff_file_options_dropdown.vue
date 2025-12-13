<script>
import {
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlDisclosureDropdownGroup,
  GlSprintf,
} from '@gitlab/ui';
import { sprintf } from '~/locale';

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
    // eslint-disable-next-line vue/no-unused-properties -- Invoked by parent component
    oldPath: {
      type: String,
      required: false,
      default: null,
    },
    // eslint-disable-next-line vue/no-unused-properties -- Invoked by parent component
    newPath: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    isGrouped() {
      return this.items.length > 0 && this.items[0].items !== undefined;
    },
  },
  mounted() {
    // We need to refocus the toggle because the original toggle is replaced with this component
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
    <template v-if="isGrouped">
      <gl-disclosure-dropdown-group
        v-for="(group, index) in items"
        :key="index"
        :group="group"
        :bordered="group.bordered"
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
      <gl-disclosure-dropdown-item v-for="(item, index) in items" :key="index" :item="item">
        <template #list-item>
          <gl-sprintf :message="transformMessage(item)">
            <template #code="{ content }">
              <code v-text="content"></code>
            </template>
          </gl-sprintf>
        </template>
      </gl-disclosure-dropdown-item>
    </template>
  </gl-disclosure-dropdown>
</template>
