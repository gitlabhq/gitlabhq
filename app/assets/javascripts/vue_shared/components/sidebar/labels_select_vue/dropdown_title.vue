<script>
import { mapState, mapActions } from 'vuex';
import { GlDeprecatedButton, GlLoadingIcon } from '@gitlab/ui';

export default {
  components: {
    GlDeprecatedButton,
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
      <gl-loading-icon v-show="labelsSelectInProgress" inline />
      <gl-deprecated-button
        variant="link"
        class="pull-right js-sidebar-dropdown-toggle"
        data-qa-selector="labels_edit_button"
        @click="toggleDropdownContents"
        >{{ __('Edit') }}</gl-deprecated-button
      >
    </template>
  </div>
</template>
