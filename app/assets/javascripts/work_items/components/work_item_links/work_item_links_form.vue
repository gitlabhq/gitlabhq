<script>
import { GlForm, GlFormInput, GlButton } from '@gitlab/ui';

export default {
  components: {
    GlForm,
    GlFormInput,
    GlButton,
  },
  data() {
    return {
      relatedWorkItem: '',
    };
  },
};
</script>

<template>
  <gl-form @submit.prevent>
    <gl-form-input v-model="relatedWorkItem" class="gl-mb-4" />
    <gl-button type="submit" category="secondary" variant="confirm">
      {{ s__('WorkItem|Add') }}
    </gl-button>
    <gl-button category="tertiary" class="gl-float-right" @click="$emit('cancel')">
      {{ s__('WorkItem|Cancel') }}
    </gl-button>
  </gl-form>
</template>
