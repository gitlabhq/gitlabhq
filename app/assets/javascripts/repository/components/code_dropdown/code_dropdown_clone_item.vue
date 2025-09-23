<script>
import {
  GlButton,
  GlDisclosureDropdownItem,
  GlFormGroup,
  GlFormInputGroup,
  GlToast,
  GlTooltipDirective,
} from '@gitlab/ui';
import Vue from 'vue';
import { __ } from '~/locale';
import { InternalEvents } from '~/tracking';

Vue.use(GlToast);
export default {
  components: {
    GlDisclosureDropdownItem,
    GlFormGroup,
    GlFormInputGroup,
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [InternalEvents.mixin()],
  props: {
    label: {
      type: String,
      required: true,
    },
    link: {
      type: String,
      required: true,
    },
    inputId: {
      type: String,
      required: false,
      default: '',
    },
    name: {
      type: String,
      required: false,
      default: null,
    },
    testId: {
      type: String,
      required: true,
    },
    tracking: {
      type: Object,
      required: false,
      default: () => ({ action: null }),
    },
  },
  methods: {
    onCopyUrl() {
      this.$toast.show(__('Copied'));

      this.trackCopyClick();
    },

    trackCopyClick() {
      const { action } = this.tracking;
      if (action) {
        this.trackEvent(action);
      }
    },
  },
  copyURLTooltip: __('Copy URL'),
};
</script>
<template>
  <gl-disclosure-dropdown-item>
    <gl-form-group
      :label="label"
      label-class="!gl-text-sm !gl-pt-2"
      :label-for="inputId"
      class="gl-mb-3 gl-px-3 gl-text-left"
    >
      <gl-form-input-group
        :id="inputId"
        :value="link"
        :name="name"
        :data-testid="inputId"
        :label="label"
        readonly
        select-on-click
      >
        <template #append>
          <gl-button
            v-gl-tooltip.hover
            :title="$options.copyURLTooltip"
            :aria-label="$options.copyURLTooltip"
            :data-clipboard-text="link"
            :data-testid="testId"
            icon="copy-to-clipboard"
            class="gl-inline-flex"
            @click="onCopyUrl"
          />
        </template>
      </gl-form-input-group>
    </gl-form-group>
  </gl-disclosure-dropdown-item>
</template>
