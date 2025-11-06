<script>
import { GlDrawer, GlButton, GlFormRadioGroup, GlFormRadio } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import { findSelectedOptionValueByLabel } from './utils';
import {
  SQUASH_SETTING_DEFAULT,
  SQUASH_SETTING_DO_NOT_ALLOW,
  SQUASH_SETTING_ALLOW,
  SQUASH_SETTING_ENCOURAGE,
  SQUASH_SETTING_REQUIRE,
  I18N,
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
      default: null,
    },
    isAllBranchesRule: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      selected: null,
    };
  },
  computed: {
    getDrawerHeaderHeight() {
      return getContentWrapperHeight();
    },
    selectedOptionValue() {
      return findSelectedOptionValueByLabel(this.squashOptions, this.selectedOption);
    },
    hasChanged() {
      return !this.selectedOption || this.selected !== this.selectedOptionValue;
    },
    squashOptions() {
      return [
        ...(!this.isAllBranchesRule
          ? [
              {
                value: SQUASH_SETTING_DEFAULT,
                label: I18N.squashDefaultLabel,
                description: I18N.squashDefaultDescription,
              },
            ]
          : []),
        ...this.$options.OPTIONS,
      ];
    },
  },
  mounted() {
    this.selected = findSelectedOptionValueByLabel(this.squashOptions, this.selectedOption);
  },
  methods: {
    submit() {
      if (this.selected === SQUASH_SETTING_DEFAULT && !this.selectedOption) {
        this.$emit('close');
        return;
      }
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
        <gl-form-radio v-for="option in squashOptions" :key="option.value" :value="option.value">
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
