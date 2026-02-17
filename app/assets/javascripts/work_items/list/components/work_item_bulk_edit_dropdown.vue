<script>
import { GlCollapsibleListbox, GlFormGroup } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import { __ } from '~/locale';
import { BULK_EDIT_NO_VALUE } from '~/work_items/constants';

export default {
  name: 'WorkItemBulkEditDropdown',
  components: {
    GlCollapsibleListbox,
    GlFormGroup,
  },
  props: {
    headerText: {
      type: String,
      required: true,
    },
    items: {
      type: Array,
      required: true,
    },
    label: {
      type: String,
      required: true,
    },
    noValueText: {
      type: String,
      required: false,
      default: undefined,
    },
    value: {
      type: String,
      required: false,
      default: undefined,
    },
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  emits: ['input'],
  data() {
    return {
      dropdownToggleId: uniqueId('wi-dropdown-toggle-'),
    };
  },
  computed: {
    listboxItems() {
      if (this.noValueText) {
        return [
          {
            text: this.noValueText,
            textSrOnly: true,
            options: [{ text: this.noValueText, value: BULK_EDIT_NO_VALUE }],
          },
          {
            text: __('All'),
            textSrOnly: true,
            options: this.items,
          },
        ];
      }

      return this.items;
    },
    toggleText() {
      if (this.value === BULK_EDIT_NO_VALUE) {
        return this.noValueText;
      }
      const selected = this.items.find((option) => option.value === this.value);
      return selected?.text || this.headerText;
    },
  },
  methods: {
    reset() {
      this.$emit('input', undefined);
      this.$refs.listbox.close?.();
    },
  },
};
</script>

<template>
  <gl-form-group :label="label" :label-for="dropdownToggleId">
    <gl-collapsible-listbox
      ref="listbox"
      block
      :header-text="headerText"
      is-check-centered
      :items="listboxItems"
      :reset-button-label="__('Reset')"
      :selected="value"
      :toggle-id="dropdownToggleId"
      :toggle-text="toggleText"
      :disabled="disabled"
      @reset="reset"
      @select="$emit('input', $event)"
    />
  </gl-form-group>
</template>
