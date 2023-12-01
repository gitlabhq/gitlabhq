<script>
export default {
  props: {
    label: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <li class="gl-line-height-20 gl-py-3 gl-border-b-solid gl-border-b-2 gl-border-b-gray-100">
    <label class="gl-font-weight-bold gl-mb-2"> {{ label }} </label>
    <div class="gl-text-gray-500 gl-mb-0">
      <slot></slot>
    </div>
  </li>
</template>
