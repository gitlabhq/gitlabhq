<script>
import { GlTable, GlButton, GlModalDirective, GlSprintf } from '@gitlab/ui';
import { mapState, mapActions } from 'vuex';
import { s__, __ } from '~/locale';

export default {
  fields: [
    {
      key: 'freezeStart',
      label: s__('DeployFreeze|Freeze start'),
    },
    {
      key: 'freezeEnd',
      label: s__('DeployFreeze|Freeze end'),
    },
    {
      key: 'cronTimezone',
      label: s__('DeployFreeze|Time zone'),
    },
  ],
  translations: {
    addDeployFreeze: __('Add deploy freeze'),
  },
  components: {
    GlTable,
    GlButton,
    GlSprintf,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  computed: {
    ...mapState(['freezePeriods']),
    tableIsNotEmpty() {
      return this.freezePeriods?.length > 0;
    },
  },
  mounted() {
    this.fetchFreezePeriods();
  },
  methods: {
    ...mapActions(['fetchFreezePeriods']),
  },
};
</script>

<template>
  <div class="deploy-freeze-table">
    <gl-table
      data-testid="deploy-freeze-table"
      :items="freezePeriods"
      :fields="$options.fields"
      show-empty
      stacked="lg"
    >
      <template #empty>
        <p data-testid="empty-freeze-periods" class="gl-text-center text-plain">
          <gl-sprintf
            :message="
              s__(
                'DeployFreeze|No deploy freezes exist for this project. To add one, click %{strongStart}Add deploy freeze%{strongEnd}',
              )
            "
          >
            <template #strong="{ content }">
              <strong>{{ content }}</strong>
            </template>
          </gl-sprintf>
        </p>
      </template>
    </gl-table>
    <gl-button
      v-gl-modal.deploy-freeze-modal
      data-testid="add-deploy-freeze"
      category="primary"
      variant="success"
    >
      {{ $options.translations.addDeployFreeze }}
    </gl-button>
  </div>
</template>
