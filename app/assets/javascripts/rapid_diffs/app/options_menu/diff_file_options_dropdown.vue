<script>
import { GlDisclosureDropdown, GlDisclosureDropdownItem, GlSprintf } from '@gitlab/ui';
import { sprintf } from '~/locale';

export default {
  name: 'DiffFileOptionsMenu',
  components: { GlDisclosureDropdown, GlDisclosureDropdownItem, GlSprintf },
  props: {
    items: {
      type: Array,
      required: true,
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
  },
};
</script>

<template>
  <gl-disclosure-dropdown
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
    <gl-disclosure-dropdown-item v-for="(item, index) in items" :key="index" :item="item">
      <template #list-item>
        <gl-sprintf :message="transformMessage(item)">
          <template #code="{ content }">
            <code v-text="content"></code>
          </template>
        </gl-sprintf>
      </template>
    </gl-disclosure-dropdown-item>
  </gl-disclosure-dropdown>
</template>
