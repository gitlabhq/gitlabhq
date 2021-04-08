<script>
import { GlDropdown, GlDropdownItem, GlIcon, GlSprintf } from '@gitlab/ui';
import { __ } from '~/locale';
import { STAGE_VIEW, LAYER_VIEW } from './constants';

export default {
  name: 'GraphViewSelector',
  components: {
    GlDropdown,
    GlDropdownItem,
    GlIcon,
    GlSprintf,
  },
  props: {
    type: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      currentViewType: STAGE_VIEW,
    };
  },
  i18n: {
    labelText: __('Order jobs by'),
  },
  views: {
    [STAGE_VIEW]: {
      type: STAGE_VIEW,
      text: {
        primary: __('Stage'),
        secondary: __('View the jobs grouped into stages'),
      },
    },
    [LAYER_VIEW]: {
      type: LAYER_VIEW,
      text: {
        primary: __('%{codeStart}needs:%{codeEnd} relationships'),
        secondary: __('View what jobs are needed for a job to run'),
      },
    },
  },
  computed: {
    currentDropdownText() {
      return this.$options.views[this.type].text.primary;
    },
  },
  methods: {
    itemClick(type) {
      this.$emit('updateViewType', type);
    },
  },
};
</script>

<template>
  <div class="gl-display-flex gl-align-items-center gl-my-4">
    <span>{{ $options.i18n.labelText }}</span>
    <gl-dropdown class="gl-ml-4">
      <template #button-content>
        <gl-sprintf :message="currentDropdownText">
          <template #code="{ content }">
            <code> {{ content }} </code>
          </template>
        </gl-sprintf>
        <gl-icon class="gl-px-2" name="angle-down" :size="16" />
      </template>
      <gl-dropdown-item
        v-for="view in $options.views"
        :key="view.type"
        :secondary-text="view.text.secondary"
        @click="itemClick(view.type)"
      >
        <b>
          <gl-sprintf :message="view.text.primary">
            <template #code="{ content }">
              <code> {{ content }} </code>
            </template>
          </gl-sprintf>
        </b>
      </gl-dropdown-item>
    </gl-dropdown>
  </div>
</template>
