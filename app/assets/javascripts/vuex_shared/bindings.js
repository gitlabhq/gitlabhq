export const mapComputed = (root, updateFn, list) => {
  const result = {};
  list.forEach(key => {
    result[key] = {
      get() {
        return this.$store.state[root][key];
      },
      set(value) {
        this.$store.dispatch(updateFn, { [key]: value });
      },
    };
  });
  return result;
};

export default () => {};
