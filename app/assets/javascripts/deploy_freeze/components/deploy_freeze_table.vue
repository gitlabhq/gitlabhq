<script>
import { GlTable, GlButton, GlModalDirective, GlSprintf } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import { mapState, mapActions } from 'vuex';
import { MODAL_ID } from '../constants';

export default {
  modalId: MODAL_ID,
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
    GlModalDirective,
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
    <div class="gl-display-flex gl-justify-content-center">
      <gl-button
        v-gl-modal-directive="$options.modalId"
        data-testid="add-deploy-freeze"
        category="primary"
        variant="success"
      >
        {{ $options.translations.addDeployFreeze }}
      </gl-button>
    </div>
  </div>
</template>
