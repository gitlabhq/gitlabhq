<script>
import { GlIcon, GlFormGroup, GlFormRadio, GlFormRadioGroup, GlLink } from '@gitlab/ui';
import {
  SNIPPET_VISIBILITY,
  SNIPPET_VISIBILITY_PRIVATE,
  SNIPPET_VISIBILITY_INTERNAL,
  SNIPPET_VISIBILITY_PUBLIC,
} from '~/snippets/constants';

export default {
  components: {
    GlIcon,
    GlFormGroup,
    GlFormRadio,
    GlFormRadioGroup,
    GlLink,
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
      required: false,
      default: SNIPPET_VISIBILITY_PRIVATE,
    },
  },
  computed: {
    visibilityOptions() {
      return [
        SNIPPET_VISIBILITY_PRIVATE,
        SNIPPET_VISIBILITY_INTERNAL,
        SNIPPET_VISIBILITY_PUBLIC,
      ].map(key => ({ value: key, ...SNIPPET_VISIBILITY[key] }));
    },
  },
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
    <gl-form-group id="visibility-level-setting">
      <gl-form-radio-group v-bind="$attrs" :checked="value" stacked v-on="$listeners">
        <gl-form-radio
          v-for="option in visibilityOptions"
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
  </div>
</template>
