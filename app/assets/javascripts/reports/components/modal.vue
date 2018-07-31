<script>
  import Modal from '~/vue_shared/components/gl_modal.vue';
  import LoadingButton from '~/vue_shared/components/loading_button.vue';
  import CodeBlock from '~/vue_shared/components/code_block.vue';
  import { fieldTypes } from '../constants';

  export default {
    components: {
      Modal,
      LoadingButton,
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
        <label class="col-sm-2 text-right font-weight-bold">
          {{ field.text }}:
        </label>

        <div class="col-sm-10 text-secondary">
          <code-block
            v-if="field.type === $options.fieldTypes.codeBock"
            :code="field.value"
          />

          <template v-else-if="field.type === $options.fieldTypes.link">
            <a
              :href="field.value"
              target="_blank"
              rel="noopener noreferrer"
              class="js-modal-link"
            >
              {{ field.value }}
            </a>
          </template>

          <template v-else-if="field.type === $options.fieldTypes.miliseconds">
            {{ field.value }} ms
          </template>

          <template v-else-if="field.type === $options.fieldTypes.text">
            {{ field.value }}
          </template>
        </div>
      </div>
    </slot>
    <div slot="footer">
    </div>
  </modal>
</template>
