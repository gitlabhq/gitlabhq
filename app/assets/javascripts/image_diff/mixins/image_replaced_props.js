export function validator(value) {
  return value.path && value.alt && value.size;
}

export const mixin = {
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
