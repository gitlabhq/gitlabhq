<script>
import { GlForm, GlFormGroup, GlFormInput } from '@gitlab/ui';
import { __ } from '~/locale';
import Tracking from '~/tracking';
import { TRACKING_CATEGORY_SHOW } from '../constants';
import localUpdateWorkItemMutation from '../graphql/local_update_work_item.mutation.graphql';

/* eslint-disable @gitlab/require-i18n-strings */
const allowedKeys = [
  'Alt',
  'ArrowDown',
  'ArrowLeft',
  'ArrowRight',
  'ArrowUp',
  'Backspace',
  'Control',
  'Delete',
  'End',
  'Enter',
  'Home',
  'Meta',
  'PageDown',
  'PageUp',
  'Tab',
  '0',
  '1',
  '2',
  '3',
  '4',
  '5',
  '6',
  '7',
  '8',
  '9',
];
/* eslint-enable @gitlab/require-i18n-strings */

export default {
  inputId: 'weight-widget-input',
  components: {
    GlForm,
    GlFormGroup,
    GlFormInput,
  },
  mixins: [Tracking.mixin()],
  inject: ['hasIssueWeightsFeature'],
  props: {
    canUpdate: {
      type: Boolean,
      required: false,
      default: false,
    },
    weight: {
      type: Number,
      required: false,
      default: undefined,
    },
    workItemId: {
      type: String,
      required: true,
    },
    workItemType: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isEditing: false,
    };
  },
  computed: {
    placeholder() {
      return this.canUpdate && this.isEditing ? __('Enter a number') : __('None');
    },
    tracking() {
      return {
        category: TRACKING_CATEGORY_SHOW,
        label: 'item_weight',
        property: `type_${this.workItemType}`,
      };
    },
    type() {
      return this.canUpdate && this.isEditing ? 'number' : 'text';
    },
  },
  methods: {
    blurInput() {
      this.$refs.input.$el.blur();
    },
    handleFocus() {
      this.isEditing = true;
    },
    handleKeydown(event) {
      if (!allowedKeys.includes(event.key)) {
        event.preventDefault();
      }
    },
    updateWeight(event) {
      this.isEditing = false;
      this.track('updated_weight');
      this.$apollo.mutate({
        mutation: localUpdateWorkItemMutation,
        variables: {
          input: {
            id: this.workItemId,
            weight: event.target.value === '' ? null : Number(event.target.value),
          },
        },
      });
    },
  },
};
</script>

<template>
  <gl-form v-if="hasIssueWeightsFeature" @submit.prevent="blurInput">
    <gl-form-group
      class="gl-align-items-center"
      :label="__('Weight')"
      :label-for="$options.inputId"
      label-class="gl-pb-0! gl-overflow-wrap-break"
      label-cols="3"
      label-cols-lg="2"
    >
      <gl-form-input
        :id="$options.inputId"
        ref="input"
        min="0"
        :placeholder="placeholder"
        :readonly="!canUpdate"
        size="sm"
        :type="type"
        :value="weight"
        @blur="updateWeight"
        @focus="handleFocus"
        @keydown="handleKeydown"
        @keydown.exact.esc.stop="blurInput"
      />
    </gl-form-group>
  </gl-form>
</template>
