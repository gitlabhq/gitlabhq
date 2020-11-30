<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import { GlButtonGroup, GlButton, GlDropdown } from '@gitlab/ui';

export default {
  components: {
    GlButtonGroup,
    GlButton,
    GlDropdown,
  },
  computed: {
    ...mapGetters('diffs', ['isInlineView', 'isParallelView']),
    ...mapState('diffs', ['renderTreeList', 'showWhitespace']),
  },
  methods: {
    ...mapActions('diffs', [
      'setInlineDiffViewType',
      'setParallelDiffViewType',
      'setRenderTreeList',
      'setShowWhitespace',
    ]),
  },
};
</script>

<template>
  <gl-dropdown
    icon="settings"
    :text="__('Diff view settings')"
    :text-sr-only="true"
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
    <div class="gl-mt-3 gl-px-3">
      <label class="gl-mb-0">
        <input
          id="show-whitespace"
          type="checkbox"
          :checked="showWhitespace"
          @change="setShowWhitespace({ showWhitespace: $event.target.checked, pushState: true })"
        />
        {{ __('Show whitespace changes') }}
      </label>
    </div>
  </gl-dropdown>
</template>
