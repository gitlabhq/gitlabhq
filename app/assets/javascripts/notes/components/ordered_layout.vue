<script>
import { normalizeRender } from '~/lib/utils/vue3compat/normalize_render';

export default normalizeRender({
  functional: true,
  render(h, context) {
    const slotKeys = context.props.slotKeys ?? context.props['slot-keys'];
    const slots = context.slots();
    const children = slotKeys.map((key) => slots[key]).filter((x) => x);

    return children;
  },
});
</script>
