<script>
import { GlButton, GlLoadingIcon } from '@gitlab/ui';
import { mapState, mapActions } from 'vuex';

export default {
  components: {
    GlButton,
    GlLoadingIcon,
  },
  props: {
    labelsSelectInProgress: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    ...mapState(['allowLabelEdit', 'labelsFetchInProgress']),
  },
  methods: {
    ...mapActions(['toggleDropdownContents']),
  },
};
</script>

<template>
  <div class="title hide-collapsed gl-mb-3">
    {{ __('Labels') }}
    <template v-if="allowLabelEdit">
      <gl-loading-icon v-show="labelsSelectInProgress" size="sm" inline />
      <gl-button
        variant="link"
        class="float-right js-sidebar-dropdown-toggle"
        data-qa-selector="labels_edit_button"
        @click="toggleDropdownContents"
        >{{ __('Edit') }}</gl-button
      >
    </template>
  </div>
</template>
