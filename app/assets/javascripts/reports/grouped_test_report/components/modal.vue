<script>
import { GlModal, GlLink, GlSprintf } from '@gitlab/ui';

import CodeBlock from '~/vue_shared/components/code_block.vue';
import { fieldTypes } from '../../constants';

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
  computed: {
    filteredModalData() {
      // Filter out the properties that don't have a value
      return Object.fromEntries(
        Object.entries(this.modalData).filter((data) => Boolean(data[1].value)),
      );
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
    <div v-for="(field, key, index) in filteredModalData" :key="index" class="row gl-mt-3 gl-mb-3">
      <strong class="col-sm-3 text-right"> {{ field.text }}: </strong>

      <div class="col-sm-9 text-secondary">
        <code-block v-if="field.type === $options.fieldTypes.codeBlock" :code="field.value" />

        <gl-link
          v-else-if="field.type === $options.fieldTypes.link"
          :href="field.value.path"
          target="_blank"
        >
          {{ field.value.text }}
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
