export default {
  // TODO: Get feedback on whether mixin props is a good idea or not
  props: {
    images: {
      type: Object,
      required: true,
      validator: value => value.added || value.deleted,
    },
  },
};
