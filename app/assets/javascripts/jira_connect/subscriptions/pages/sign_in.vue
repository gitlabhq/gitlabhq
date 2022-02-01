<script>
import { s__ } from '~/locale';
import SubscriptionsList from '../components/subscriptions_list.vue';
import SignInButton from '../components/sign_in_button.vue';

export default {
  name: 'SignInPage',
  components: {
    SubscriptionsList,
    SignInButton,
  },
  inject: ['usersPath'],
  props: {
    hasSubscriptions: {
      type: Boolean,
      required: true,
    },
  },
  i18n: {
    signinButtonTextWithSubscriptions: s__('Integrations|Sign in to add namespaces'),
    signInText: s__('JiraService|Sign in to GitLab.com to get started.'),
  },
};
</script>

<template>
  <div v-if="hasSubscriptions">
    <div class="gl-display-flex gl-justify-content-end">
      <sign-in-button :users-path="usersPath">
        {{ $options.i18n.signinButtonTextWithSubscriptions }}
      </sign-in-button>
    </div>

    <subscriptions-list />
  </div>
  <div v-else class="gl-text-center">
    <p class="gl-mb-7">{{ $options.i18n.signInText }}</p>
    <sign-in-button class="gl-mb-7" :users-path="usersPath" />
  </div>
</template>
