<script>
// eslint-disable-next-line no-restricted-imports
import { mapGetters, mapState } from 'vuex';

import DropdownContentsCreateView from './dropdown_contents_create_view.vue';
import DropdownContentsLabelsView from './dropdown_contents_labels_view.vue';

// @deprecated This component should only be used when there is no GraphQL API.
// In most cases you should use
// `app/assets/javascripts/sidebar/components/labels/labels_select_widget/dropdown_contents.vue` instead.
export default {
  components: {
    DropdownContentsLabelsView,
    DropdownContentsCreateView,
  },
  props: {
    renderOnTop: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    ...mapState(['showDropdownContentsCreateView']),
    ...mapGetters(['isDropdownVariantSidebar']),
    dropdownContentsView() {
      if (this.showDropdownContentsCreateView) {
        return 'dropdown-contents-create-view';
      }
      return 'dropdown-contents-labels-view';
    },
    directionStyle() {
      const bottom = this.isDropdownVariantSidebar ? '3rem' : '2rem';
      return this.renderOnTop ? { bottom } : {};
    },
  },
};
</script>

<template>
  <div
    class="labels-select-dropdown-contents gl-absolute gl-my-2 gl-w-full gl-rounded-base gl-py-3"
    data-testid="labels-select-dropdown-contents"
    :style="directionStyle"
  >
    <component :is="dropdownContentsView" />
  </div>
</template>
