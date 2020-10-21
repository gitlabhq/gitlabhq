<script>
import { GlModal } from '@gitlab/ui';
import { __ } from '~/locale';
import CodeBlock from '~/vue_shared/components/code_block.vue';

export default {
  name: 'TestCaseDetails',
  components: {
    CodeBlock,
    GlModal,
  },
  props: {
    modalId: {
      type: String,
      required: true,
    },
    testCase: {
      type: Object,
      required: true,
      validator: ({ classname, formattedTime, name }) =>
        Boolean(classname) && Boolean(formattedTime) && Boolean(name),
    },
  },
  text: {
    name: __('Name'),
    duration: __('Execution time'),
    trace: __('System output'),
  },
  modalCloseButton: {
    text: __('Close'),
    attributes: [{ variant: 'info' }],
  },
};
</script>

<template>
  <gl-modal
    :modal-id="modalId"
    :title="testCase.classname"
    :action-primary="$options.modalCloseButton"
  >
    <div class="gl-display-flex gl-flex-wrap gl-mx-n4 gl-my-3">
      <strong class="gl-text-right col-sm-3">{{ $options.text.name }}</strong>
      <div class="col-sm-9" data-testid="test-case-name">
        {{ testCase.name }}
      </div>
    </div>

    <div class="gl-display-flex gl-flex-wrap gl-mx-n4 gl-my-3">
      <strong class="gl-text-right col-sm-3">{{ $options.text.duration }}</strong>
      <div class="col-sm-9" data-testid="test-case-duration">
        {{ testCase.formattedTime }}
      </div>
    </div>

    <div
      v-if="testCase.system_output"
      class="gl-display-flex gl-flex-wrap gl-mx-n4 gl-my-3"
      data-testid="test-case-trace"
    >
      <strong class="gl-text-right col-sm-3">{{ $options.text.trace }}</strong>
      <div class="col-sm-9">
        <code-block :code="testCase.system_output" />
      </div>
    </div>
  </gl-modal>
</template>
