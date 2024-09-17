<!-- eslint-disable vue/multi-word-component-names -->
<script>
import CreateForm from '../components/form.vue';

export default {
  components: {
    CreateForm,
  },
  methods: {
    redirectToIndex() {
      this.$router.push('/');
    },
  },
};
</script>

<template>
  <div>
    <h5 class="gl-mt-0 gl-text-lg">
      {{ __('Add new emoji') }}
    </h5>
    <create-form @saved="redirectToIndex" />
  </div>
</template>
