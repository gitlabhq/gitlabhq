<script>
import { GlIcon } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: {
    GlIcon,
  },
  i18n: {
    help: __('Help'),
    new: __('New'),
  },
};
</script>

<template>
  <div class="bottom-links gl-p-3">
    <a href="#" class="gl-text-black-normal"
      ><gl-icon name="question-o" class="gl-mr-3 gl-text-gray-300 gl-text-black-normal!" />{{
        $options.i18n.help
      }}</a
    >
  </div>
</template>
