<script>
import { getExperimentVariant } from '../utils';

export default {
  props: {
    name: {
      type: String,
      required: true,
    },
  },
  render() {
    return this.$slots?.[getExperimentVariant(this.name)];
  },
};
</script>
