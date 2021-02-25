<script>
import { GlFormGroup, GlFormRadio, GlFormText } from '@gitlab/ui';

export default {
  name: 'ProjectsField',
  ALL_PROJECTS: 'ALL_PROJECTS',
  SELECTED_PROJECTS: 'SELECTED_PROJECTS',
  components: { GlFormGroup, GlFormRadio, GlFormText },
  props: {
    inputAttrs: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      selectedRadio: this.$options.ALL_PROJECTS,
    };
  },
};
</script>

<template>
  <div>
    <gl-form-group :label="__('Projects')" label-class="gl-pb-0!">
      <gl-form-text class="gl-pb-3">{{
        __('Set access permissions for this token.')
      }}</gl-form-text>
      <gl-form-radio v-model="selectedRadio" :value="$options.ALL_PROJECTS">{{
        __('All projects')
      }}</gl-form-radio>
      <gl-form-radio v-model="selectedRadio" :value="$options.SELECTED_PROJECTS">{{
        __('Selected projects')
      }}</gl-form-radio>
      <input :id="inputAttrs.id" type="hidden" :name="inputAttrs.name" />
    </gl-form-group>
  </div>
</template>
