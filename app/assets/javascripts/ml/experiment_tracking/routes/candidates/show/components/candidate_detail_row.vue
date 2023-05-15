<script>
import { GlLink } from '@gitlab/ui';

export default {
  name: 'CandidateDetailRow',
  components: {
    GlLink,
  },
  props: {
    label: {
      type: String,
      required: true,
    },
    text: {
      type: [String, Number],
      required: true,
    },
    href: {
      type: String,
      required: false,
      default: '',
    },
    sectionLabel: {
      type: String,
      required: false,
      default: '',
    },
  },
};
</script>

<template>
  <tr>
    <td class="gl-text-secondary gl-font-weight-bold">{{ sectionLabel }}</td>
    <td class="gl-font-weight-bold">{{ label }}</td>
    <td>
      <gl-link v-if="href" :href="href">{{ text }}</gl-link>
      <template v-else>{{ text }}</template>
    </td>
  </tr>
</template>
