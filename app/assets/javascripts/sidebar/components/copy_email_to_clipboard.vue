<script>
import CopyableField from '../../vue_shared/components/sidebar/copyable_field.vue';

export default {
  components: {
    CopyableField,
  },
  props: {
    issueEmailAddress: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <copyable-field
    data-qa-selector="copy-forward-email"
    :name="s__('RightSidebar|Issue email')"
    :clipboard-tooltip-text="s__('RightSidebar|Copy email address')"
    :value="issueEmailAddress"
  />
</template>
