import refQuery from '../queries/ref.query.graphql';

// Kept exportable: Vue 3 has no merge strategy for the custom `apollo` option,
// so a component defining its own `apollo` block silently DROPS this mixin's
// entry and must re-declare it (`apollo: { ref: refApolloQuery, ... }`) and
// initialize `ref` in its own data() (vue-no-undef-apollo-properties is
// per-component and cannot see this mixin's data).
export const refApolloQuery = {
  query: refQuery,
  manual: true,
  result({ data, loading }) {
    if (data && !loading) {
      this.ref = data.ref;
      this.escapedRef = data.escapedRef;
    }
  },
};

export default {
  apollo: {
    ref: refApolloQuery,
  },
  data() {
    return {
      ref: '',
      escapedRef: '',
    };
  },
};
