export default {
  props: {
    images: {
      type: Object,
      required: true,
      validator: value => value.added || value.deleted,
    },
  },
};
