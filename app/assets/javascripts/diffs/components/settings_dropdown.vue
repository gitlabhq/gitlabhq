<script>
import {
  GlButtonGroup,
  GlButton,
  GlDropdown,
  GlFormCheckbox,
  GlTooltipDirective,
} from '@gitlab/ui';
import { mapActions, mapGetters, mapState } from 'vuex';
import { SETTINGS_DROPDOWN } from '../i18n';

export default {
  i18n: SETTINGS_DROPDOWN,
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlButtonGroup,
    GlButton,
    GlDropdown,
    GlFormCheckbox,
  },
  computed: {
    ...mapGetters('diffs', ['isInlineView', 'isParallelView']),
    ...mapState('diffs', ['renderTreeList', 'showWhitespace', 'viewDiffsFileByFile']),
  },
  methods: {
    ...mapActions('diffs', [
      'setInlineDiffViewType',
      'setParallelDiffViewType',
      'setRenderTreeList',
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
  <gl-dropdown
    v-gl-tooltip
    icon="settings"
    :title="$options.i18n.preferences"
    :text="$options.i18n.preferences"
    :text-sr-only="true"
    :aria-label="$options.i18n.preferences"
    :header-text="$options.i18n.preferences"
    toggle-class="js-show-diff-settings"
    right
  >
    <div class="gl-px-3">
      <span class="gl-font-weight-bold gl-display-block gl-mb-2">{{ __('File browser') }}</span>
      <gl-button-group class="gl-display-flex">
        <gl-button
          :class="{ selected: !renderTreeList }"
          class="gl-w-half js-list-view"
          @click="setRenderTreeList(false)"
        >
          {{ __('List view') }}
        </gl-button>
        <gl-button
          :class="{ selected: renderTreeList }"
          class="gl-w-half js-tree-view"
          @click="setRenderTreeList(true)"
        >
          {{ __('Tree view') }}
        </gl-button>
      </gl-button-group>
    </div>
    <div class="gl-mt-3 gl-px-3">
      <span class="gl-font-weight-bold gl-display-block gl-mb-2">{{ __('Compare changes') }}</span>
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
  </gl-dropdown>
</template>
