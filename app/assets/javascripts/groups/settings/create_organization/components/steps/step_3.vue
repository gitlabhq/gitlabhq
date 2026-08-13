<script>
import BaseStep from './base_step.vue';

export default {
  name: 'ReconciliationStep3',
  components: {
    BaseStep,
  },
};
</script>

<template>
  <base-step :title="s__('Organization|Confirm your organization')">
    <template #description>
      <p>
        {{
          s__(
            'Organization|After you confirm your organization structure, your data will be transferred to your organization.',
          )
        }}
      </p>
    </template>
  </base-step>
</template>
