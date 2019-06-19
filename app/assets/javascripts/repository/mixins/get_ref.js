import getRef from '../queries/getRef.query.graphql';

export default {
  apollo: {
    ref: {
      query: getRef,
    },
  },
  data() {
    return {
      ref: '',
    };
  },
};
