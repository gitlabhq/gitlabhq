<script>
import { GlButton, GlFormGroup } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  i18n: {
    add: __('Add to board'),
    cancel: __('Cancel'),
    newList: __('New list'),
    scope: __('Scope'),
    scopeDescription: __('Issues must match this scope to appear in this list.'),
    requiredFieldFeedback: __('This field is required.'),
  },
  components: {
    GlButton,
    GlFormGroup,
  },
  props: {
    searchLabel: {
      type: String,
      required: false,
      default: null,
    },
    selectedIdValid: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      searchValue: '',
    };
  },
  methods: {
    onSubmit() {
      this.$emit('add-list');
    },
  },
};
</script>

<template>
  <div
    class="board-add-new-list board gl-display-inline-block gl-h-full gl-vertical-align-top gl-white-space-normal gl-flex-shrink-0 gl-rounded-base gl-px-3"
    data-testid="board-add-new-column"
  >
    <div
      class="gl-display-flex gl-flex-direction-column gl-relative gl-h-full gl-rounded-base gl-bg-gray-50"
    >
      <h3 class="gl-font-size-h2 gl-px-5 gl-py-5 gl-m-0" data-testid="board-add-column-form-title">
        {{ $options.i18n.newList }}
      </h3>

      <div
        class="gl-display-flex gl-flex-direction-column gl-h-full gl-overflow-y-auto gl-align-items-flex-start"
      >
        <div class="gl-px-5">
          <h3 class="gl-font-lg gl-mt-3 gl-mb-2">
            {{ $options.i18n.scope }}
          </h3>
          <p class="gl-mb-3">{{ $options.i18n.scopeDescription }}</p>
        </div>

        <slot name="select-list-type"></slot>

        <gl-form-group
          class="gl-px-5 lg-mb-3 gl-max-w-full"
          :label="searchLabel"
          :state="selectedIdValid"
          :invalid-feedback="$options.i18n.requiredFieldFeedback"
        >
          <slot name="dropdown"></slot>
        </gl-form-group>
      </div>
      <div class="gl-display-flex gl-mb-4">
        <gl-button
          data-testid="addNewColumnButton"
          variant="confirm"
          class="gl-mr-3 gl-ml-4"
          @click="onSubmit"
          >{{ $options.i18n.add }}</gl-button
        >
        <gl-button
          data-testid="cancelAddNewColumn"
          @click="$emit('setAddColumnFormVisibility', false)"
          >{{ $options.i18n.cancel }}</gl-button
        >
      </div>
    </div>
  </div>
</template>
