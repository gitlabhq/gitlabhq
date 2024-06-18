<script>
export default {
  name: 'CandidateDetailRow',
  props: {
    label: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <tr>
    <td class="gl-font-bold">{{ label }}</td>
    <td>
      <slot></slot>
    </td>
  </tr>
</template>
