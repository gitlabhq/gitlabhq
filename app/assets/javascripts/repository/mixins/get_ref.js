import refQuery from '../queries/ref.query.graphql';

export default {
  apollo: {
    ref: {
      query: refQuery,
      manual: true,
      result({ data, loading }) {
        if (!loading) {
          this.ref = data.ref;
          this.escapedRef = data.escapedRef;
        }
      },
    },
  },
  data() {
    return {
      ref: '',
      escapedRef: '',
    };
  },
};
