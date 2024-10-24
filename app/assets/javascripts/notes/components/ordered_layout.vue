<script>
export default {
  functional: true,
  render(h, context) {
    const { slotKeys } = context.props;
    const slots = context.slots();
    const children = slotKeys.map((key) => slots[key]).filter((x) => x);

    return children;
  },
};
</script>
