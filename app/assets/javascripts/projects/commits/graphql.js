import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';

export default new VueApollo({
  defaultClient: createDefaultClient(),
});
