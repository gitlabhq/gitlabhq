<script>
import { GlForm, GlFormInput, GlFormGroup } from '@gitlab/ui';
import { humanize } from '~/lib/utils/text_utility';

export default {
  components: {
    GlForm,
    GlFormInput,
    GlFormGroup,
  },
  props: {
    settings: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      editableSettings: { ...this.settings },
    };
  },
  methods: {
    getId(type, key) {
      return `sse-front-matter-${type}-${key}`;
    },
    getIsSupported(val) {
      return ['string', 'number'].includes(typeof val);
    },
    getLabel(str) {
      return humanize(str);
    },
    onUpdate() {
      this.$emit('updateSettings', { ...this.editableSettings });
    },
  },
};
</script>
<template>
  <gl-form>
    <template v-for="(value, key) of editableSettings">
      <gl-form-group
        v-if="getIsSupported(value)"
        :id="getId('form-group', key)"
        :key="key"
        :label="getLabel(key)"
        :label-for="getId('control', key)"
      >
        <gl-form-input
          :id="getId('control', key)"
          v-model.lazy="editableSettings[key]"
          type="text"
          @input="onUpdate"
        />
      </gl-form-group>
    </template>
  </gl-form>
</template>
