<script>
import { GlIcon, GlFormGroup, GlFormRadio, GlFormRadioGroup, GlLink } from '@gitlab/ui';
import defaultVisibilityQuery from '../queries/snippet_visibility.query.graphql';
import { defaultSnippetVisibilityLevels } from '../utils/blob';
import { SNIPPET_LEVELS_RESTRICTED, SNIPPET_LEVELS_DISABLED } from '~/snippets/constants';

export default {
  components: {
    GlIcon,
    GlFormGroup,
    GlFormRadio,
    GlFormRadioGroup,
    GlLink,
  },
  apollo: {
    defaultVisibility: {
      query: defaultVisibilityQuery,
      manual: true,
      result({ data: { visibilityLevels, multipleLevelsRestricted } }) {
        this.visibilityLevels = defaultSnippetVisibilityLevels(visibilityLevels);
        this.multipleLevelsRestricted = multipleLevelsRestricted;
      },
    },
  },
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
  data() {
    return {
      visibilityLevels: [],
      multipleLevelsRestricted: false,
    };
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
          v-for="option in visibilityLevels"
          :key="option.value"
          :value="option.value"
          class="mb-3"
        >
          <div class="d-flex align-items-center">
            <gl-icon :size="16" :name="option.icon" />
            <span class="font-weight-bold ml-1 js-visibility-option">{{ option.label }}</span>
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
      <template v-if="!visibilityLevels.length">{{ $options.SNIPPET_LEVELS_DISABLED }}</template>
      <template v-else-if="multipleLevelsRestricted">{{
        $options.SNIPPET_LEVELS_RESTRICTED
      }}</template>
    </div>
  </div>
</template>
