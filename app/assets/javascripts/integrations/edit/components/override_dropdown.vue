<script>
import { GlCollapsibleListbox, GlLink } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState } from 'vuex';
import { s__ } from '~/locale';
import { defaultIntegrationLevel, overrideDropdownDescriptions } from '~/integrations/constants';

const dropdownOptions = [
  {
    value: 'default',
    text: s__('Integrations|Use default settings'),
  },
  {
    value: 'custom',
    text: s__('Integrations|Use custom settings'),
  },
];

export default {
  dropdownOptions,
  name: 'OverrideDropdown',
  components: {
    GlCollapsibleListbox,
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
    const selectedValue = this.override ? 'custom' : 'default';
    return {
      selectedValue,
      selectedOption: dropdownOptions.find((x) => x.value === selectedValue),
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
    onSelect(value) {
      this.selectedValue = value;
      this.selectedOption = dropdownOptions.find((item) => item.value === value);
      this.$emit('change', value === 'custom');
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
    <gl-collapsible-listbox
      v-model="selectedValue"
      :toggle-text="selectedOption.text"
      :items="$options.dropdownOptions"
      @select="onSelect"
    />
  </div>
</template>
