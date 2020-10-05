<script>
import { mapState } from 'vuex';

import DropdownContentsLabelsView from './dropdown_contents_labels_view.vue';
import DropdownContentsCreateView from './dropdown_contents_create_view.vue';

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
    dropdownContentsView() {
      if (this.showDropdownContentsCreateView) {
        return 'dropdown-contents-create-view';
      }
      return 'dropdown-contents-labels-view';
    },
    directionStyle() {
      if (this.renderOnTop) {
        return { bottom: '100%' };
      }

      return {};
    },
  },
};
</script>

<template>
  <div
    class="labels-select-dropdown-contents w-100 mt-1 mb-3 py-2 rounded-top rounded-bottom position-absolute"
    data-qa-selector="labels_dropdown_content"
    :style="directionStyle"
  >
    <component :is="dropdownContentsView" />
  </div>
</template>
