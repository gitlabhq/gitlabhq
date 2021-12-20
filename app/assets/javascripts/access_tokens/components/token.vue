<script>
import InputCopyToggleVisibility from '~/vue_shared/components/form/input_copy_toggle_visibility.vue';

export default {
  components: { InputCopyToggleVisibility },
  props: {
    token: {
      type: String,
      required: true,
    },
    inputId: {
      type: String,
      required: true,
    },
    inputLabel: {
      type: String,
      required: true,
    },
    copyButtonTitle: {
      type: String,
      required: true,
    },
  },
  computed: {
    formInputGroupProps() {
      return { id: this.inputId };
    },
  },
};
</script>

<template>
  <div class="row">
    <div class="col-lg-12">
      <hr />
    </div>
    <div class="col-lg-4">
      <h4 class="gl-mt-0"><slot name="title"></slot></h4>
      <slot name="description"></slot>
    </div>
    <div class="col-lg-8">
      <input-copy-toggle-visibility
        :label="inputLabel"
        :label-for="inputId"
        :form-input-group-props="formInputGroupProps"
        :value="token"
        :copy-button-title="copyButtonTitle"
      >
        <template #description>
          <slot name="input-description"></slot>
        </template>
      </input-copy-toggle-visibility>
    </div>
  </div>
</template>
