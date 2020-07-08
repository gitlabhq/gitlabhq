import getRef from '../queries/getRef.query.graphql';

export default {
  apollo: {
    ref: {
      query: getRef,
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
