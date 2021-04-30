<script>
import { mapGetters, mapState } from 'vuex';

import DropdownContentsCreateView from './dropdown_contents_create_view.vue';
import DropdownContentsLabelsView from './dropdown_contents_labels_view.vue';

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
    class="labels-select-dropdown-contents gl-w-full gl-my-2 gl-py-3 gl-rounded-base gl-absolute"
    data-qa-selector="labels_dropdown_content"
    :style="directionStyle"
  >
    <component :is="dropdownContentsView" />
  </div>
</template>
