export function validator(value) {
  return value.path && value.alt;
}

export const mixin = {
  // TODO: Get feedback on whether mixin props is a good idea or not
  props: {
    added: {
      type: Object,
      required: true,
      validator,
    },
    deleted: {
      type: Object,
      required: true,
      validator,
    },
  },
};
