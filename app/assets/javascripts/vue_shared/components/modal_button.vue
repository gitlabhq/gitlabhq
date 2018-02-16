<script>
  const buttonVariants = [
    'danger',
    'default',
    'primary',
    'success',
    'warning',
  ];

  export default {
    name: 'ModalButton',

    props: {
      variant: {
        type: String,
        required: false,
        default: 'default',
        validator: value => buttonVariants.indexOf(value) !== -1,
      },
    },
  };
</script>

<template>
  <button
    type="button"
    class="btn"
    :class="`btn-${variant}`"
    data-dismiss="modal">
    <slot></slot>
  </button>
</template>
