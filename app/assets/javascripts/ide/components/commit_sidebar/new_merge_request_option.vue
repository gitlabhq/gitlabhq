<script>
import { GlTooltipDirective } from '@gitlab/ui';
import { createNamespacedHelpers } from 'vuex';
import { s__ } from '~/locale';

const { mapActions: mapCommitActions, mapGetters: mapCommitGetters } = createNamespacedHelpers(
  'commit',
);

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  computed: {
    ...mapCommitGetters(['shouldHideNewMrOption', 'shouldDisableNewMrOption', 'shouldCreateMR']),
    tooltipText() {
      if (this.shouldDisableNewMrOption) {
        return s__(
          'IDE|This option is disabled because you are not allowed to create merge requests in this project.',
        );
      }

      return '';
    },
  },
  methods: {
    ...mapCommitActions(['toggleShouldCreateMR']),
  },
};
</script>

<template>
  <fieldset v-if="!shouldHideNewMrOption">
    <hr class="my-2" />
    <label
      v-gl-tooltip="tooltipText"
      class="mb-0 js-ide-commit-new-mr"
      :class="{ 'is-disabled': shouldDisableNewMrOption }"
    >
      <input
        :disabled="shouldDisableNewMrOption"
        :checked="shouldCreateMR"
        type="checkbox"
        @change="toggleShouldCreateMR"
      />
      <span class="gl-ml-3 ide-option-label">
        {{ __('Start a new merge request') }}
      </span>
    </label>
  </fieldset>
</template>
