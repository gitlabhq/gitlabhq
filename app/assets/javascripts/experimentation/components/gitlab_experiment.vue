<script>
import { getSlotFunction, normalizeRender } from '~/lib/utils/vue3compat/normalize_render';
import { getExperimentVariant } from '../utils';

export default normalizeRender({
  props: {
    name: {
      type: String,
      required: true,
    },
  },
  render() {
    return getSlotFunction(this, getExperimentVariant(this.name))?.();
  },
});
</script>
