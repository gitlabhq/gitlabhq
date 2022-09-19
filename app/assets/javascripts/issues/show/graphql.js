import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { defaultClient } from '~/graphql_shared/issuable_client';

Vue.use(VueApollo);

export default new VueApollo({
  defaultClient,
});
