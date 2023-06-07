<script>
export default {
  name: 'CandidateDetailRow',
  props: {
    label: {
      type: String,
      required: true,
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
      <slot></slot>
    </td>
  </tr>
</template>
