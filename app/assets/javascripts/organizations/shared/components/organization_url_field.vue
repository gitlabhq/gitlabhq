<script>
import { GlFormInputGroup, GlFormInput, GlInputGroupText, GlTruncate } from '@gitlab/ui';
import { s__ } from '~/locale';
import { joinPaths } from '~/lib/utils/url_utility';

export default {
  name: 'OrganizationUrlField',
  components: {
    GlFormInputGroup,
    GlFormInput,
    GlInputGroupText,
    GlTruncate,
  },
  i18n: {
    pathPlaceholder: s__('Organization|my-organization'),
  },
  formId: 'new-organization-form',
  inject: ['organizationsPath', 'rootUrl'],
  props: {
    id: {
      type: String,
      required: true,
    },
    value: {
      type: String,
      required: true,
    },
    validation: {
      type: Object,
      required: true,
    },
  },
  computed: {
    baseUrl() {
      return joinPaths(this.rootUrl, this.organizationsPath, '/');
    },
  },
};
</script>

<template>
  <gl-form-input-group class="gl-md-form-input-xl form-control gl-border-0 gl-p-0">
    <template #prepend>
      <gl-input-group-text class="organization-root-path">
        <gl-truncate :text="baseUrl" position="middle" />
      </gl-input-group-text>
    </template>
    <gl-form-input
      v-bind="validation"
      :id="id"
      :value="value"
      :placeholder="$options.i18n.pathPlaceholder"
      class="!gl-h-auto"
      @input="$emit('input', $event)"
      @blur="$emit('blur', $event)"
    />
  </gl-form-input-group>
</template>
