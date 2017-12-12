<script>
import Store from '../../stores/sidebar_store';
import participants from './participants.vue';

export default {
  data() {
    return {
      store: new Store(),
    };
  },
  props: {
    mediator: {
      type: Object,
      required: true,
    },
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
      :number-of-less-participants="7"
    />
  </div>
</template>
