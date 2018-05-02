<script>
  import Participants from '~/sidebar/components/participants/participants.vue';

  export default {
    components: {
      Participants,
    },
    props: {
      participants: {
        type: Array,
        required: true,
      },
    },
  };
</script>

<template>
  <div class="block participants">
    <participants
      :participants="participants"
    />
  </div>
</template>
