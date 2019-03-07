<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import { GlButton } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    GlButton,
    Icon,
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
  <div class="dropdown">
    <button
      type="button"
      class="btn btn-default js-show-diff-settings"
      data-toggle="dropdown"
      data-display="static"
    >
      <icon name="settings" /> <icon name="arrow-down" />
    </button>
    <div class="dropdown-menu dropdown-menu-right p-2 pt-3 pb-3">
      <div>
        <span class="bold d-block mb-1">{{ __('File browser') }}</span>
        <div class="btn-group d-flex">
          <gl-button
            :class="{ active: !renderTreeList }"
            class="w-100 js-list-view"
            @click="setRenderTreeList(false)"
          >
            {{ __('List view') }}
          </gl-button>
          <gl-button
            :class="{ active: renderTreeList }"
            class="w-100 js-tree-view"
            @click="setRenderTreeList(true)"
          >
            {{ __('Tree view') }}
          </gl-button>
        </div>
      </div>
      <div class="mt-2">
        <span class="bold d-block mb-1">{{ __('Compare changes') }}</span>
        <div class="btn-group d-flex js-diff-view-buttons">
          <gl-button
            id="inline-diff-btn"
            :class="{ active: isInlineView }"
            class="w-100 js-inline-diff-button"
            data-view-type="inline"
            @click="setInlineDiffViewType"
          >
            {{ __('Inline') }}
          </gl-button>
          <gl-button
            id="parallel-diff-btn"
            :class="{ active: isParallelView }"
            class="w-100 js-parallel-diff-button"
            data-view-type="parallel"
            @click="setParallelDiffViewType"
          >
            {{ __('Side-by-side') }}
          </gl-button>
        </div>
      </div>
      <div class="mt-2">
        <label class="mb-0">
          <input
            id="show-whitespace"
            type="checkbox"
            :checked="showWhitespace"
            @change="setShowWhitespace({ showWhitespace: $event.target.checked, pushState: true })"
          />
          {{ __('Show whitespace changes') }}
        </label>
      </div>
    </div>
  </div>
</template>
