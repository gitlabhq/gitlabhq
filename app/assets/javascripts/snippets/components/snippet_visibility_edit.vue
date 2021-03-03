<script>
import { GlIcon, GlFormGroup, GlFormRadio, GlFormRadioGroup, GlLink } from '@gitlab/ui';
import { SNIPPET_LEVELS_RESTRICTED, SNIPPET_LEVELS_DISABLED } from '~/snippets/constants';
import { defaultSnippetVisibilityLevels } from '../utils/blob';

export default {
  components: {
    GlIcon,
    GlFormGroup,
    GlFormRadio,
    GlFormRadioGroup,
    GlLink,
  },
  inject: ['visibilityLevels', 'multipleLevelsRestricted'],
  props: {
    helpLink: {
      type: String,
      default: '',
      required: false,
    },
    isProjectSnippet: {
      type: Boolean,
      required: false,
      default: false,
    },
    value: {
      type: String,
      required: true,
    },
  },
  computed: {
    defaultVisibilityLevels() {
      return defaultSnippetVisibilityLevels(this.visibilityLevels);
    },
  },
  SNIPPET_LEVELS_DISABLED,
  SNIPPET_LEVELS_RESTRICTED,
};
</script>
<template>
  <div class="form-group">
    <label>
      {{ __('Visibility level') }}
      <gl-link v-if="helpLink" :href="helpLink" target="_blank"
        ><gl-icon :size="12" name="question"
      /></gl-link>
    </label>
    <gl-form-group id="visibility-level-setting" class="gl-mb-0">
      <gl-form-radio-group :checked="value" stacked v-bind="$attrs" v-on="$listeners">
        <gl-form-radio
          v-for="option in defaultVisibilityLevels"
          :key="option.value"
          :value="option.value"
          class="mb-3"
        >
          <div class="d-flex align-items-center">
            <gl-icon :size="16" :name="option.icon" />
            <span
              class="font-weight-bold ml-1 js-visibility-option"
              data-qa-selector="visibility_content"
              :data-qa-visibility="option.label"
              >{{ option.label }}</span
            >
          </div>
          <template #help>{{
            isProjectSnippet && option.description_project
              ? option.description_project
              : option.description
          }}</template>
        </gl-form-radio>
      </gl-form-radio-group>
    </gl-form-group>

    <div class="text-muted" data-testid="restricted-levels-info">
      <template v-if="!defaultVisibilityLevels.length">{{
        $options.SNIPPET_LEVELS_DISABLED
      }}</template>
      <template v-else-if="multipleLevelsRestricted">{{
        $options.SNIPPET_LEVELS_RESTRICTED
      }}</template>
    </div>
  </div>
</template>
