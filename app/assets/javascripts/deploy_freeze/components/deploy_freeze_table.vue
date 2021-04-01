<script>
import { GlTable, GlButton, GlModalDirective, GlSprintf } from '@gitlab/ui';
import { mapState, mapActions } from 'vuex';
import { s__ } from '~/locale';

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
    {
      key: 'edit',
      label: s__('DeployFreeze|Edit'),
    },
  ],
  translations: {
    addDeployFreeze: s__('DeployFreeze|Add deploy freeze'),
    emptyStateText: s__(
      'DeployFreeze|No deploy freezes exist for this project. To add one, select %{strongStart}Add deploy freeze%{strongEnd}',
    ),
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
    ...mapActions(['fetchFreezePeriods', 'setFreezePeriod']),
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
      <template #cell(cronTimezone)="{ item }">
        {{ item.cronTimezone.formattedTimezone }}
      </template>
      <template #cell(edit)="{ item }">
        <gl-button
          v-gl-modal.deploy-freeze-modal
          icon="pencil"
          data-testid="edit-deploy-freeze"
          :aria-label="__('Edit deploy freeze')"
          @click="setFreezePeriod(item)"
        />
      </template>
      <template #empty>
        <p data-testid="empty-freeze-periods" class="gl-text-center text-plain">
          <gl-sprintf :message="$options.translations.emptyStateText">
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
      variant="confirm"
    >
      {{ $options.translations.addDeployFreeze }}
    </gl-button>
  </div>
</template>
