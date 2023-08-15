<script>
import { GlFormGroup, GlFormInput } from '@gitlab/ui';
import { uniqueId } from 'lodash';
// eslint-disable-next-line no-restricted-imports
import { mapState } from 'vuex';
import FormFieldContainer from './form_field_container.vue';

export default {
  name: 'TagFieldExisting',
  components: { GlFormGroup, GlFormInput, FormFieldContainer },
  computed: {
    ...mapState('editNew', ['release']),
    inputId() {
      return uniqueId('tag-name-input-');
    },
    helpId() {
      return uniqueId('tag-name-help-');
    },
  },
};
</script>
<template>
  <gl-form-group :label="__('Tag name')" :label-for="inputId">
    <form-field-container>
      <gl-form-input
        :id="inputId"
        :value="release.tagName"
        type="text"
        class="form-control"
        :aria-describedby="helpId"
        disabled
      />
    </form-field-container>
    <template #description>
      <div :id="helpId" data-testid="tag-name-help">
        {{ __("The tag name can't be changed for an existing release.") }}
      </div>
    </template>
  </gl-form-group>
</template>
