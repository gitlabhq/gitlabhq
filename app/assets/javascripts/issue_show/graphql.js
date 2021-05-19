import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { defaultClient } from '~/sidebar/graphql';

Vue.use(VueApollo);

export default new VueApollo({
  defaultClient,
});
