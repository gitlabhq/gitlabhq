<script>
import {
  GlButtonGroup,
  GlButton,
  GlDisclosureDropdown,
  GlFormCheckbox,
  GlTooltip,
} from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapGetters, mapState } from 'vuex';
import { SETTINGS_DROPDOWN } from '../i18n';

export default {
  i18n: SETTINGS_DROPDOWN,
  toggleId: 'js-show-diff-settings',
  components: {
    GlButtonGroup,
    GlButton,
    GlDisclosureDropdown,
    GlFormCheckbox,
    GlTooltip,
  },
  computed: {
    ...mapGetters('diffs', ['isInlineView', 'isParallelView']),
    ...mapState('diffs', ['showWhitespace', 'viewDiffsFileByFile']),
  },
  methods: {
    ...mapActions('diffs', [
      'setInlineDiffViewType',
      'setParallelDiffViewType',
      'setShowWhitespace',
      'setFileByFile',
    ]),
    toggleFileByFile() {
      this.setFileByFile({ fileByFile: !this.viewDiffsFileByFile });
    },
    toggleWhitespace(updatedSetting) {
      this.setShowWhitespace({ showWhitespace: updatedSetting });
    },
  },
};
</script>

<template>
  <div>
    <gl-disclosure-dropdown
      :toggle-class="$options.toggleId"
      :toggle-id="$options.toggleId"
      icon="settings"
      :text="$options.i18n.preferences"
      text-sr-only
      :aria-label="$options.i18n.preferences"
      placement="right"
      :auto-close="false"
    >
      <slot name="header">
        <span
          class="gl-font-weight-bold gl-display-block gl-mb-3 gl-pb-2 gl-text-center gl-border-b"
          >{{ $options.i18n.preferences }}</span
        >
      </slot>
      <div class="gl-mt-3 gl-px-3">
        <span class="gl-font-weight-bold gl-display-block gl-mb-2">{{
          __('Compare changes')
        }}</span>
        <gl-button-group class="gl-display-flex js-diff-view-buttons">
          <gl-button
            id="inline-diff-btn"
            :class="{ selected: isInlineView }"
            class="gl-w-half js-inline-diff-button"
            data-view-type="inline"
            @click="setInlineDiffViewType"
          >
            {{ __('Inline') }}
          </gl-button>
          <gl-button
            id="parallel-diff-btn"
            :class="{ selected: isParallelView }"
            class="gl-w-half js-parallel-diff-button"
            data-view-type="parallel"
            @click="setParallelDiffViewType"
          >
            {{ __('Side-by-side') }}
          </gl-button>
        </gl-button-group>
      </div>
      <gl-form-checkbox
        data-testid="show-whitespace"
        class="gl-mt-3 gl-ml-3"
        :checked="showWhitespace"
        @input="toggleWhitespace"
      >
        {{ $options.i18n.whitespace }}
      </gl-form-checkbox>
      <gl-form-checkbox
        data-testid="file-by-file"
        class="gl-ml-3 gl-mb-0"
        :checked="viewDiffsFileByFile"
        @input="toggleFileByFile"
      >
        {{ $options.i18n.fileByFile }}
      </gl-form-checkbox>
    </gl-disclosure-dropdown>

    <gl-tooltip :target="$options.toggleId" triggers="hover">{{
      $options.i18n.preferences
    }}</gl-tooltip>
  </div>
</template>
