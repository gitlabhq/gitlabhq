<script>
import { GlModal, GlLink, GlSprintf } from '@gitlab/ui';

import CodeBlock from '~/vue_shared/components/code_block.vue';
import { fieldTypes } from '../constants';

export default {
  components: {
    CodeBlock,
    GlModal,
    GlLink,
    GlSprintf,
  },
  props: {
    visible: {
      type: Boolean,
      required: true,
    },
    title: {
      type: String,
      required: true,
    },
    modalData: {
      type: Object,
      required: true,
    },
  },
  fieldTypes,
};
</script>
<template>
  <gl-modal
    :visible="visible"
    modal-id="modal-mrwidget-reports"
    :title="title"
    :hide-footer="true"
    @hide="$emit('hide')"
  >
    <div
      v-for="(field, key, index) in modalData"
      v-if="field.value"
      :key="index"
      class="row gl-mt-3 gl-mb-3"
    >
      <strong class="col-sm-3 text-right"> {{ field.text }}: </strong>

      <div class="col-sm-9 text-secondary">
        <code-block v-if="field.type === $options.fieldTypes.codeBock" :code="field.value" />

        <gl-link
          v-else-if="field.type === $options.fieldTypes.link"
          :href="field.value"
          target="_blank"
        >
          {{ field.value }}
        </gl-link>

        <gl-sprintf
          v-else-if="field.type === $options.fieldTypes.seconds"
          :message="__('%{value} s')"
        >
          <template #value>{{ field.value }}</template>
        </gl-sprintf>

        <template v-else-if="field.type === $options.fieldTypes.text">
          {{ field.value }}
        </template>
      </div>
    </div>
  </gl-modal>
</template>
