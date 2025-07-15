<script>
import { GlDrawer } from '@gitlab/ui';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { formatInputsForDisplay } from './utils';

export default {
  components: {
    GlDrawer,
  },
  props: {
    open: {
      type: Boolean,
      required: true,
    },
    inputs: {
      type: Array,
      required: true,
    },
  },
  computed: {
    getDrawerHeaderHeight() {
      return getContentWrapperHeight();
    },
    formattedLines() {
      return formatInputsForDisplay(this.inputs);
    },
  },
  methods: {
    onClose() {
      this.$emit('close');
    },
  },
  DRAWER_Z_INDEX,
};
</script>

<template>
  <gl-drawer
    :open="open"
    :header-height="getDrawerHeaderHeight"
    :z-index="$options.DRAWER_Z_INDEX"
    @close="onClose"
  >
    <template #title>
      <h2 class="gl-my-0 gl-text-size-h2 gl-leading-24">
        {{ s__('Pipelines|Preview your inputs') }}
      </h2>
    </template>
    <div>
      <p>{{ s__('Pipelines|The pipeline will run with these inputs:') }}</p>

      <div class="file-content code" data-testid="inputs-code-block">
        <pre class="!gl-border-1 !gl-border-solid !gl-border-subtle gl-p-3"><div
          v-for="(line, index) in formattedLines"
          :key="index"
          :class="{
            'gl-text-danger': line.type === 'old',
            'gl-text-success': line.type === 'new'
          }"
          class="line"
          data-testid="inputs-code-line"
        >{{ line.content }}</div></pre>
      </div>
    </div>
  </gl-drawer>
</template>
