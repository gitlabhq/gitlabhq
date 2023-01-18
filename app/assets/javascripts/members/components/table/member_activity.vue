<script>
import UserDate from '~/vue_shared/components/user_date.vue';

export default {
  components: { UserDate },
  props: {
    member: {
      type: Object,
      required: true,
    },
  },
  computed: {
    userCreated() {
      return this.member.user?.createdAt;
    },
    lastActivity() {
      return this.member.user?.lastActivityOn;
    },
  },
};
</script>

<template>
  <div>
    <div v-if="userCreated">
      <strong>{{ s__('Members|User created') }}:</strong>
      <user-date :date="userCreated" />
    </div>
    <div v-if="member.createdAt">
      <strong>{{ s__('Members|Access granted') }}:</strong>
      <user-date :date="member.createdAt" />
    </div>
    <div v-if="lastActivity">
      <strong>{{ s__('Members|Last activity') }}:</strong>
      <user-date :date="lastActivity" />
    </div>
  </div>
</template>
