<script>
import {
  GlButton,
  GlDropdown,
  GlFormGroup,
  GlIcon,
  GlSearchBoxByType,
  GlSkeletonLoader,
} from '@gitlab/ui';
import { mapActions } from 'vuex';
import { __ } from '~/locale';

export default {
  i18n: {
    add: __('Add to board'),
    cancel: __('Cancel'),
    newList: __('New list'),
    noResults: __('No matching results'),
    scope: __('Scope'),
    scopeDescription: __('Issues must match this scope to appear in this list.'),
    selected: __('Selected'),
  },
  components: {
    GlButton,
    GlDropdown,
    GlFormGroup,
    GlIcon,
    GlSearchBoxByType,
    GlSkeletonLoader,
  },
  props: {
    loading: {
      type: Boolean,
      required: true,
    },
    searchLabel: {
      type: String,
      required: false,
      default: null,
    },
    noneSelected: {
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
  data() {
    return {
      searchValue: '',
    };
  },
  watch: {
    selectedId(val) {
      if (val) {
        this.$refs.dropdown.hide(true);
      }
    },
  },
  methods: {
    ...mapActions(['setAddColumnFormVisibility']),
    setFocus() {
      this.$refs.searchBox.focusInput();
    },
    onHide() {
      this.searchValue = '';
      this.$emit('filter-items', '');
      this.$emit('hide');
    },
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
        class="gl-font-size-h2 gl-px-5 gl-py-4 gl-m-0 gl-border-b-1 gl-border-b-solid gl-border-b-gray-100"
        data-testid="board-add-column-form-title"
      >
        {{ $options.i18n.newList }}
      </h3>

      <div
        class="gl-display-flex gl-flex-direction-column gl-h-full gl-overflow-y-auto gl-align-items-flex-start"
      >
        <div class="gl-px-5">
          <h3 class="gl-font-lg gl-mt-5 gl-mb-2">
            {{ $options.i18n.scope }}
          </h3>
          <p class="gl-mb-3">{{ $options.i18n.scopeDescription }}</p>
        </div>

        <slot name="select-list-type"></slot>

        <gl-form-group class="gl-px-5 lg-mb-3 gl-max-w-full" :label="searchLabel">
          <gl-dropdown
            ref="dropdown"
            class="gl-mb-3 gl-max-w-full"
            toggle-class="gl-max-w-full gl-display-flex gl-align-items-center gl-text-trunate"
            boundary="viewport"
            @shown="setFocus"
            @hide="onHide"
          >
            <template #button-content>
              <slot name="selected">
                <div>{{ noneSelected }}</div>
              </slot>
              <gl-icon class="dropdown-chevron gl-flex-shrink-0" name="chevron-down" />
            </template>

            <template #header>
              <gl-search-box-by-type
                ref="searchBox"
                v-model="searchValue"
                debounce="250"
                class="gl-mt-0!"
                :placeholder="searchPlaceholder"
                @input="$emit('filter-items', $event)"
              />
            </template>

            <div v-if="loading" class="gl-px-5">
              <gl-skeleton-loader :width="400" :height="172">
                <rect width="380" height="20" x="10" y="15" rx="4" />
                <rect width="280" height="20" x="10" y="50" rx="4" />
                <rect width="330" height="20" x="10" y="85" rx="4" />
              </gl-skeleton-loader>
            </div>

            <slot v-else name="items">
              <p class="gl-mx-5">{{ $options.i18n.noResults }}</p>
            </slot>
          </gl-dropdown>
        </gl-form-group>
      </div>
      <div
        class="gl-display-flex gl-p-3 gl-border-t-1 gl-border-t-solid gl-border-gray-100 gl-bg-gray-10 gl-rounded-bottom-left-base gl-rounded-bottom-right-base"
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
          variant="confirm"
          class="gl-mr-4"
          @click="$emit('add-list')"
          >{{ $options.i18n.add }}</gl-button
        >
      </div>
    </div>
  </div>
</template>
