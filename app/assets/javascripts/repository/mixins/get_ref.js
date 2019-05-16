import getRef from '../queries/getRef.graphql';

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
