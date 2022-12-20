<script>
import CopyableField from './copyable_field.vue';

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
    data-testid="copy-forward-email"
    :name="s__('RightSidebar|Issue email')"
    :clipboard-tooltip-text="s__('RightSidebar|Copy email address')"
    :value="issueEmailAddress"
  />
</template>
