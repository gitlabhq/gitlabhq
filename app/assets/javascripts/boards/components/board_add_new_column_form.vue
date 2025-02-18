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
    class="board-add-new-list board gl-inline-block gl-h-full gl-shrink-0 gl-whitespace-normal gl-rounded-base gl-pl-2 gl-align-top"
    data-testid="board-add-new-column"
  >
    <div
      class="gl-relative gl-flex gl-h-full gl-flex-col gl-rounded-base gl-bg-strong dark:gl-bg-subtle"
    >
      <h3 class="gl-m-0 gl-px-5 gl-py-5 gl-text-size-h2" data-testid="board-add-column-form-title">
        {{ $options.i18n.newList }}
      </h3>

      <div class="gl-flex gl-h-full gl-flex-col gl-items-start gl-overflow-y-auto">
        <div class="gl-px-5">
          <h3 class="gl-mb-2 gl-mt-3 gl-text-lg">
            {{ $options.i18n.scope }}
          </h3>
          <p class="gl-mb-3">{{ $options.i18n.scopeDescription }}</p>
        </div>

        <slot name="select-list-type"></slot>

        <gl-form-group
          class="lg-mb-3 gl-max-w-full gl-px-5"
          :label="searchLabel"
          :state="selectedIdValid"
          :invalid-feedback="$options.i18n.requiredFieldFeedback"
        >
          <slot name="dropdown"></slot>
        </gl-form-group>
      </div>
      <div class="gl-mb-4 gl-flex gl-pr-4">
        <gl-button
          data-testid="addNewColumnButton"
          variant="confirm"
          class="gl-ml-4 gl-mr-3"
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
