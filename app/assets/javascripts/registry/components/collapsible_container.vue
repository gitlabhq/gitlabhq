<script>
  export default {
    name: 'collapsibeContainerRegisty',
    props: {
      canDelete: {
        type: Boolean,
        required: true,
      },
      title: {
        type: String,
        required: true,
      },
    },
    components: {

    },
    data() {
      return {
        isOpen: false,
      };
    },
    methods: {

    }
  }
</script>

<template>
  <div class="container-image">
    <i
      class="fa"
      :class="{
        'chevron-left': !isOpen,
        'chevron-up': isOpen,
      }"
      aria-hidden="true">
    </i>
    {{title}}


  </div>
</template>
