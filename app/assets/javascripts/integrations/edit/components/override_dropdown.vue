<script>
import { GlDropdown, GlDropdownItem, GlLink } from '@gitlab/ui';
import { mapState } from 'vuex';
import { s__ } from '~/locale';
import { defaultIntegrationLevel, overrideDropdownDescriptions } from '../constants';

const dropdownOptions = [
  {
    value: false,
    text: s__('Integrations|Use default settings'),
  },
  {
    value: true,
    text: s__('Integrations|Use custom settings'),
  },
];

export default {
  dropdownOptions,
  name: 'OverrideDropdown',
  components: {
    GlDropdown,
    GlDropdownItem,
    GlLink,
  },
  props: {
    inheritFromId: {
      type: Number,
      required: true,
    },
    learnMorePath: {
      type: String,
      required: false,
      default: null,
    },
    override: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      selected: dropdownOptions.find((x) => x.value === this.override),
    };
  },
  computed: {
    ...mapState(['defaultState']),
    description() {
      const level = this.defaultState.integrationLevel;

      return (
        overrideDropdownDescriptions[level] || overrideDropdownDescriptions[defaultIntegrationLevel]
      );
    },
  },
  methods: {
    onClick(option) {
      this.selected = option;
      this.$emit('change', option.value);
    },
  },
};
</script>

<template>
  <div
    class="gl-display-flex gl-justify-content-space-between gl-align-items-baseline gl-py-4 gl-mt-5 gl-mb-6 gl-border-t-1 gl-border-t-solid gl-border-b-1 gl-border-b-solid gl-border-gray-100"
  >
    <span
      >{{ description }}
      <gl-link v-if="learnMorePath" :href="learnMorePath" target="_blank">{{
        __('Learn more')
      }}</gl-link>
    </span>
    <input name="service[inherit_from_id]" :value="override ? '' : inheritFromId" type="hidden" />
    <gl-dropdown :text="selected.text">
      <gl-dropdown-item
        v-for="option in $options.dropdownOptions"
        :key="option.value"
        @click="onClick(option)"
      >
        {{ option.text }}
      </gl-dropdown-item>
    </gl-dropdown>
  </div>
</template>
