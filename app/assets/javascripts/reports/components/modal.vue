<script>
// import { sprintf, __ } from '~/locale';
import DeprecatedModal2 from '~/vue_shared/components/deprecated_modal_2.vue';
import CodeBlock from '~/vue_shared/components/code_block.vue';
import { fieldTypes } from '../constants';

export default {
  components: {
    Modal: DeprecatedModal2,
    CodeBlock,
  },
  props: {
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
  <modal
    id="modal-mrwidget-reports"
    :header-title-text="title"
    class="modal-security-report-dast modal-hide-footer"
  >
    <slot>
      <div
        v-for="(field, key, index) in modalData"
        v-if="field.value"
        :key="index"
        class="row prepend-top-10 append-bottom-10"
      >
        <strong class="col-sm-3 text-right"> {{ field.text }}: </strong>

        <div class="col-sm-9 text-secondary">
          <code-block v-if="field.type === $options.fieldTypes.codeBock" :code="field.value" />

          <template v-else-if="field.type === $options.fieldTypes.link">
            <a :href="field.value" target="_blank" rel="noopener noreferrer" class="js-modal-link">
              {{ field.value }}
            </a>
          </template>

          <template v-else-if="field.type === $options.fieldTypes.miliseconds">{{
            sprintf(__('%{value} ms'), { value: field.value })
          }}</template>

          <template v-else-if="field.type === $options.fieldTypes.text">
            {{ field.value }}
          </template>
        </div>
      </div>
    </slot>
    <div slot="footer"></div>
  </modal>
</template>
