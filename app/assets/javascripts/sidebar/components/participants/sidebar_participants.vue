<script>
import Store from '../../stores/sidebar_store';
import Mediator from '../../sidebar_mediator';
import participants from './participants.vue';

export default {
  data() {
    return {
      mediator: new Mediator(),
      store: new Store(),
    };
  },
  components: {
    participants,
  },
};
</script>

<template>
  <div class="block participants">
    <participants
      :loading="store.isFetching.participants"
      :participants="store.participants"
      :number-of-less-participants="7" />
  </div>
</template>
