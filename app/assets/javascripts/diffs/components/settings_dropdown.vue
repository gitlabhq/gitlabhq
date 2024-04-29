<script>
import { GlCollapsibleListbox, GlFormCheckbox, GlTooltip } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapState } from 'vuex';
import { __ } from '~/locale';
import { PARALLEL_DIFF_VIEW_TYPE, INLINE_DIFF_VIEW_TYPE } from '../constants';
import { SETTINGS_DROPDOWN } from '../i18n';

export default {
  i18n: SETTINGS_DROPDOWN,
  toggleId: 'js-show-diff-settings',
  components: {
    GlCollapsibleListbox,
    GlFormCheckbox,
    GlTooltip,
  },
  computed: {
    ...mapState('diffs', ['showWhitespace', 'viewDiffsFileByFile', 'diffViewType']),
  },
  methods: {
    ...mapActions('diffs', ['setDiffViewType', 'setShowWhitespace', 'setFileByFile']),
    toggleFileByFile() {
      this.setFileByFile({ fileByFile: !this.viewDiffsFileByFile });
    },
    toggleWhitespace(updatedSetting) {
      this.setShowWhitespace({ showWhitespace: updatedSetting });
    },
    tooltipTarget() {
      return document.querySelector(`.${this.$options.toggleId}`);
    },
  },
  diffViewTypeOptions: [
    {
      text: __('Side-by-side'),
      value: PARALLEL_DIFF_VIEW_TYPE,
    },
    {
      text: __('Inline'),
      value: INLINE_DIFF_VIEW_TYPE,
    },
  ],
};
</script>

<template>
  <div>
    <gl-collapsible-listbox
      :selected="diffViewType"
      :toggle-class="$options.toggleId"
      icon="preferences"
      :text="$options.i18n.preferences"
      text-sr-only
      :aria-label="$options.i18n.preferences"
      :header-text="__('Compare changes')"
      :items="$options.diffViewTypeOptions"
      @select="setDiffViewType"
    >
      <template #footer>
        <div class="gl-pt-4 gl-pb-2 gl-px-4 gl-border-t">
          <gl-form-checkbox
            data-testid="show-whitespace"
            class="gl-mb-2"
            :checked="showWhitespace"
            @input="toggleWhitespace"
          >
            {{ $options.i18n.whitespace }}
          </gl-form-checkbox>
          <gl-form-checkbox
            data-testid="file-by-file"
            class="gl-mb-0"
            :checked="viewDiffsFileByFile"
            @input="toggleFileByFile"
          >
            {{ $options.i18n.fileByFile }}
          </gl-form-checkbox>
        </div>
      </template>
    </gl-collapsible-listbox>
    <gl-tooltip :target="tooltipTarget" triggers="hover">
      {{ $options.i18n.preferences }}
    </gl-tooltip>
  </div>
</template>
