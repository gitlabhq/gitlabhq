<script>
import CreateForm from '../components/form.vue';
import List from '../components/list.vue';

export default {
  components: {
    CreateForm,
    List,
  },
};
</script>

<template>
  <div>
    <h5 class="gl-mt-0 gl-font-lg">
      {{ __('Add new saved reply') }}
    </h5>
    <create-form />
    <list />
  </div>
</template>
