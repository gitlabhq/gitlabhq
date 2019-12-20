<script>
import { GlDropdown, GlDropdownItem, GlIcon } from '@gitlab/ui';
import { s__ } from '../../locale';

export default {
  name: 'CrossplaneProviderStack',
  components: {
    GlDropdown,
    GlDropdownItem,
    GlIcon,
  },
  props: {
    stacks: {
      type: Array,
      required: false,
      default: () => [
        {
          name: s__('Google Cloud Platform'),
          code: 'gcp',
        },
        {
          name: s__('Amazon Web Services'),
          code: 'aws',
        },
        {
          name: s__('Microsoft Azure'),
          code: 'azure',
        },
        {
          name: s__('Rook'),
          code: 'rook',
        },
      ],
    },
    crossplane: {
      type: Object,
      required: true,
    },
  },
  computed: {
    dropdownText() {
      const result = this.stacks.reduce((map, obj) => {
        // eslint-disable-next-line no-param-reassign
        map[obj.code] = obj.name;
        return map;
      }, {});
      const { stack } = this.crossplane;
      if (stack !== '') {
        return result[stack];
      }
      return s__('Select Stack');
    },
    validationError() {
      return this.crossplane.validationError;
    },
  },
  methods: {
    selectStack(stack) {
      this.$emit('set', stack);
    },
  },
};
</script>

<template>
  <div>
    <label>
      {{ s__('ClusterIntegration|Enabled stack') }}
    </label>
    <gl-dropdown
      :disabled="crossplane.installed"
      :text="dropdownText"
      toggle-class="dropdown-menu-toggle gl-field-error-outline"
      class="w-100"
      :class="{ 'gl-show-field-errors': validationError }"
    >
      <gl-dropdown-item v-for="stack in stacks" :key="stack.code" @click="selectStack(stack)">
        <span class="ml-1">{{ stack.name }}</span>
      </gl-dropdown-item>
    </gl-dropdown>
    <span v-if="validationError" class="gl-field-error">{{ validationError }}</span>
    <p class="form-text text-muted">
      {{ s__(`You must select a stack for configuring your cloud provider. Learn more about`) }}
      <a
        href="https://crossplane.io/docs/master/stacks-guide.html"
        target="_blank"
        rel="noopener noreferrer"
        >{{ __('Crossplane') }}
        <gl-icon name="external-link" class="vertical-align-middle" />
      </a>
    </p>
  </div>
</template>
