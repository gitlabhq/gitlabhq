export function stubTransition() {
  return {
    render() {
      // eslint-disable-next-line no-underscore-dangle
      return this.$options._renderChildren;
    },
  };
}
