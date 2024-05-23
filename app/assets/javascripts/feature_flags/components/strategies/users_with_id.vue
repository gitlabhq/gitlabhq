<script>
import { GlFormTextarea } from '@gitlab/ui';
import { __, s__ } from '~/locale';

import ParameterFormGroup from './parameter_form_group.vue';

export default {
  components: {
    ParameterFormGroup,
    GlFormTextarea,
  },
  props: {
    strategy: {
      required: true,
      type: Object,
    },
  },
  translations: {
    rolloutUserIdsDescription: __('Enter one or more user ID separated by commas'),
    rolloutUserIdsLabel: s__('FeatureFlag|User IDs'),
  },
  computed: {
    userIds() {
      return this.strategy?.parameters?.userIds ?? '';
    },
  },
  methods: {
    onUserIdsChange(value) {
      this.$emit('change', {
        parameters: {
          userIds: value,
        },
      });
    },
  },
};
</script>
<template>
  <parameter-form-group
    :label="$options.translations.rolloutUserIdsLabel"
    :description="$options.translations.rolloutUserIdsDescription"
  >
    <template #default="{ inputId }">
      <gl-form-textarea :id="inputId" :value="userIds" no-resize @input="onUserIdsChange" />
    </template>
  </parameter-form-group>
</template>
