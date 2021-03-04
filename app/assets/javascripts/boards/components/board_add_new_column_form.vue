<script>
import { GlButton, GlFormGroup, GlSearchBoxByType, GlSkeletonLoader } from '@gitlab/ui';
import { mapActions } from 'vuex';
import { __ } from '~/locale';

export default {
  i18n: {
    add: __('Add'),
    cancel: __('Cancel'),
    newList: __('New list'),
    noneSelected: __('None'),
    selected: __('Selected'),
  },
  components: {
    GlButton,
    GlFormGroup,
    GlSearchBoxByType,
    GlSkeletonLoader,
  },
  props: {
    loading: {
      type: Boolean,
      required: true,
    },
    formDescription: {
      type: String,
      required: true,
    },
    searchLabel: {
      type: String,
      required: true,
    },
    searchPlaceholder: {
      type: String,
      required: true,
    },
    selectedId: {
      type: [Number, String],
      required: false,
      default: null,
    },
  },
  methods: {
    ...mapActions(['setAddColumnFormVisibility']),
  },
};
</script>

<template>
  <div
    class="board-add-new-list board gl-display-inline-block gl-h-full gl-px-3 gl-vertical-align-top gl-white-space-normal gl-flex-shrink-0"
    data-testid="board-add-new-column"
    data-qa-selector="board_add_new_list"
  >
    <div
      class="board-inner gl-display-flex gl-flex-direction-column gl-relative gl-h-full gl-rounded-base gl-bg-white"
    >
      <h3
        class="gl-font-base gl-px-5 gl-py-5 gl-m-0 gl-border-b-1 gl-border-b-solid gl-border-b-gray-100"
        data-testid="board-add-column-form-title"
      >
        {{ $options.i18n.newList }}
      </h3>

      <div class="gl-display-flex gl-flex-direction-column gl-h-full gl-overflow-hidden">
        <slot name="select-list-type">
          <div class="gl-mb-5"></div>
        </slot>

        <p class="gl-px-5">{{ formDescription }}</p>

        <div class="gl-px-5 gl-pb-4">
          <label class="gl-mb-2">{{ $options.i18n.selected }}</label>
          <slot name="selected">
            <div class="gl-text-gray-500">{{ $options.i18n.noneSelected }}</div>
          </slot>
        </div>

        <gl-form-group
          class="gl-mx-5 gl-mb-3"
          :label="searchLabel"
          label-for="board-available-column-entities"
        >
          <gl-search-box-by-type
            id="board-available-column-entities"
            debounce="250"
            :placeholder="searchPlaceholder"
            @input="$emit('filter-items', $event)"
          />
        </gl-form-group>

        <div v-if="loading" class="gl-px-5">
          <gl-skeleton-loader :width="500" :height="172">
            <rect width="480" height="20" x="10" y="15" rx="4" />
            <rect width="380" height="20" x="10" y="50" rx="4" />
            <rect width="430" height="20" x="10" y="85" rx="4" />
          </gl-skeleton-loader>
        </div>

        <slot v-else name="items"></slot>
      </div>
      <div
        class="gl-display-flex gl-p-3 gl-border-t-1 gl-border-t-solid gl-border-gray-100 gl-bg-gray-10"
      >
        <gl-button
          data-testid="cancelAddNewColumn"
          class="gl-ml-auto gl-mr-3"
          @click="setAddColumnFormVisibility(false)"
          >{{ $options.i18n.cancel }}</gl-button
        >
        <gl-button
          data-testid="addNewColumnButton"
          :disabled="!selectedId"
          variant="success"
          class="gl-mr-4"
          @click="$emit('add-list')"
          >{{ $options.i18n.add }}</gl-button
        >
      </div>
    </div>
  </div>
</template>
