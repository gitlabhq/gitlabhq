<script>
import { GlDrawer, GlButton, GlFormRadioGroup, GlFormRadio } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import {
  SQUASH_SETTING_DO_NOT_ALLOW,
  SQUASH_SETTING_ALLOW,
  SQUASH_SETTING_ENCOURAGE,
  SQUASH_SETTING_REQUIRE,
} from './constants';

export default {
  DRAWER_Z_INDEX,
  i18n: {
    saveChanges: __('Save changes'),
    cancel: __('Cancel'),
    title: __('Squash commits when merging'),
  },
  OPTIONS: [
    {
      value: SQUASH_SETTING_DO_NOT_ALLOW,
      label: s__('SquashSettings|Do not allow'),
      description: s__('SquashSettings|Squashing is never performed and the checkbox is hidden.'),
    },
    {
      value: SQUASH_SETTING_ALLOW,
      label: s__('SquashSettings|Allow'),
      description: s__('SquashSettings|Checkbox is visible and unselected by default.'),
    },
    {
      value: SQUASH_SETTING_ENCOURAGE,
      label: s__('SquashSettings|Encourage'),
      description: s__('SquashSettings|Checkbox is visible and selected by default.'),
    },
    {
      value: SQUASH_SETTING_REQUIRE,
      label: s__('SquashSettings|Require'),
      description: s__(
        'SquashSettings|Squashing is always performed. Checkbox is visible and selected, and users cannot change it.',
      ),
    },
  ],
  components: { GlDrawer, GlFormRadioGroup, GlButton, GlFormRadio },
  props: {
    isOpen: {
      type: Boolean,
      required: true,
    },
    isLoading: {
      type: Boolean,
      required: true,
    },
    selectedOption: {
      type: String,
      required: false,
      default: SQUASH_SETTING_DO_NOT_ALLOW,
    },
  },
  data() {
    return {
      selected: this.selectedOption,
    };
  },
  computed: {
    getDrawerHeaderHeight() {
      return getContentWrapperHeight();
    },
    hasChanged() {
      return this.selected !== this.selectedOption;
    },
  },
  methods: {
    submit() {
      this.$emit('submit', this.selected);
    },
  },
};
</script>

<template>
  <gl-drawer
    :header-height="getDrawerHeaderHeight"
    :z-index="$options.DRAWER_Z_INDEX"
    :open="isOpen"
    @ok="submit"
    v-on="$listeners"
  >
    <template #title>
      <h2 class="gl-my-0 gl-text-size-h2">{{ $options.i18n.title }}</h2>
    </template>

    <template #default>
      <gl-form-radio-group v-model="selected" class="gl-border-none !gl-pb-0">
        <gl-form-radio v-for="option in $options.OPTIONS" :key="option.value" :value="option.value">
          {{ option.label }}
          <template #help>{{ option.description }}</template>
        </gl-form-radio>
      </gl-form-radio-group>

      <div class="gl-flex gl-gap-3">
        <gl-button variant="confirm" :disabled="!hasChanged" :loading="isLoading" @click="submit">
          {{ $options.i18n.saveChanges }}
        </gl-button>
        <gl-button variant="confirm" category="secondary" @click="$emit('close')">
          {{ $options.i18n.cancel }}
        </gl-button>
      </div>
    </template>
  </gl-drawer>
</template>
