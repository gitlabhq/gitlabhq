<script>
  import Store from '../../stores/sidebar_store';
  import participants from './participants.vue';

  export default {
    components: {
      participants,
    },
    props: {
      mediator: {
        type: Object,
        required: true,
      },
    },
    data() {
      return {
        store: new Store(),
      };
    },
  };
</script>

<template>
  <div class="block participants">
    <participants
      :loading="store.isFetching.participants"
      :participants="store.participants"
      :number-of-less-participants="7"
    />
  </div>
</template>
