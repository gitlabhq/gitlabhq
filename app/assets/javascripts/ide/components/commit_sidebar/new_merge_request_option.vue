<script>
import { GlTooltipDirective, GlFormCheckbox } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { createNamespacedHelpers } from 'vuex';
import { s__ } from '~/locale';

const { mapActions: mapCommitActions, mapGetters: mapCommitGetters } =
  createNamespacedHelpers('commit');

export default {
  components: { GlFormCheckbox },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  i18n: {
    newMrText: s__('IDE|Start a new merge request'),
    tooltipText: s__(
      'IDE|This option is disabled because you are not allowed to create merge requests in this project.',
    ),
  },
  computed: {
    ...mapCommitGetters(['shouldHideNewMrOption', 'shouldDisableNewMrOption', 'shouldCreateMR']),
    tooltipText() {
      return this.shouldDisableNewMrOption ? this.$options.i18n.tooltipText : null;
    },
  },
  methods: {
    ...mapCommitActions(['toggleShouldCreateMR']),
  },
};
</script>

<template>
  <fieldset
    v-if="!shouldHideNewMrOption"
    v-gl-tooltip="tooltipText"
    data-testid="new-merge-request-fieldset"
    class="js-ide-commit-new-mr"
    :class="{ 'is-disabled': shouldDisableNewMrOption }"
  >
    <hr class="gl-mb-4 gl-mt-3" />

    <gl-form-checkbox
      :disabled="shouldDisableNewMrOption"
      :checked="shouldCreateMR"
      @change="toggleShouldCreateMR"
    >
      <span class="ide-option-label">
        {{ $options.i18n.newMrText }}
      </span>
    </gl-form-checkbox>
  </fieldset>
</template>
