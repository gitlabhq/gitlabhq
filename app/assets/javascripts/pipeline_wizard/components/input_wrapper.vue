<script>
import { isNode, isDocument, isSeq, visit } from 'yaml';
import { capitalize } from 'lodash';
import TextWidget from '~/pipeline_wizard/components/widgets/text.vue';
import ListWidget from '~/pipeline_wizard/components/widgets/list.vue';
import ChecklistWidget from '~/pipeline_wizard/components/widgets/checklist.vue';

const widgets = {
  TextWidget,
  ListWidget,
  ChecklistWidget,
};

function isNullOrUndefined(v) {
  return [undefined, null].includes(v);
}

export default {
  components: {
    ...widgets,
  },
  props: {
    template: {
      type: Object,
      required: true,
      validator: (v) => isNode(v),
    },
    compiled: {
      type: Object,
      required: true,
      validator: (v) => isDocument(v) || isNode(v),
    },
    target: {
      type: String,
      required: false,
      validator: (v) => /^\$.*/g.test(v),
      default: null,
    },
    widget: {
      type: String,
      required: true,
      validator: (v) => {
        return Object.keys(widgets).includes(`${capitalize(v)}Widget`);
      },
    },
    validate: {
      type: Boolean,
      required: false,
      default: false,
    },
    monospace: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    path() {
      if (!this.target) return null;
      let res;
      visit(this.template, (seqKey, node, path) => {
        if (node && node.value === this.target) {
          // `path` is an array of objects (all the node's parents)
          // So this reducer will reduce it to an array of the path's keys,
          // e.g. `[ 'foo', 'bar', '0' ]`
          res = path.reduce((p, { key }) => (key ? [...p, `${key}`] : p), []);
          const parent = path[path.length - 1];
          if (isSeq(parent)) {
            res.push(seqKey);
          }
        }
      });
      return res;
    },
  },
  methods: {
    compile(v) {
      if (!this.path) return;
      if (isNullOrUndefined(v)) {
        this.compiled.deleteIn(this.path);
      }
      this.compiled.setIn(this.path, v);
    },
    onModelChange(v) {
      this.$emit('beforeUpdate:compiled');
      this.compile(v);
      this.$emit('update:compiled', this.compiled);
      this.$emit('highlight', this.path);
    },
    onValidationStateChange(v) {
      this.$emit('update:valid', v);
    },
  },
};
</script>

<template>
  <div>
    <component
      :is="`${widget}-widget`"
      ref="widget"
      :monospace="monospace"
      :validate="validate"
      v-bind="$attrs"
      :data-input-target="target"
      @input="onModelChange"
      @update:valid="onValidationStateChange"
    />
  </div>
</template>
