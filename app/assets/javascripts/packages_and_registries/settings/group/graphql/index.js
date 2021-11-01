import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';

Vue.use(VueApollo);

export const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});
