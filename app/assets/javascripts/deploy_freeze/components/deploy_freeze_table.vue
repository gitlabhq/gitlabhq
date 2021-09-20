<script>
import { GlTable, GlButton, GlModal, GlModalDirective, GlSprintf } from '@gitlab/ui';
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
    {
      key: 'delete',
      label: s__('DeployFreeze|Delete'),
    },
  ],
  translations: {
    addDeployFreeze: s__('DeployFreeze|Add deploy freeze'),
    deleteDeployFreezeTitle: s__('DeployFreeze|Delete deploy freeze?'),
    deleteDeployFreezeMessage: s__(
      'DeployFreeze|Deploy freeze from %{start} to %{end} in %{timezone} will be removed. Are you sure?',
    ),
    emptyStateText: s__(
      'DeployFreeze|No deploy freezes exist for this project. To add one, select %{strongStart}Add deploy freeze%{strongEnd}',
    ),
  },
  modal: {
    id: 'deleteFreezePeriodModal',
    actionPrimary: {
      text: s__('DeployFreeze|Delete freeze period'),
      attributes: { variant: 'danger', 'data-testid': 'modal-confirm' },
    },
  },
  components: {
    GlTable,
    GlButton,
    GlModal,
    GlSprintf,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  data() {
    return {
      freezePeriodToDelete: null,
    };
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
    ...mapActions(['fetchFreezePeriods', 'setFreezePeriod', 'deleteFreezePeriod']),
    handleDeleteFreezePeriod(freezePeriod) {
      this.freezePeriodToDelete = freezePeriod;
    },
    confirmDeleteFreezePeriod() {
      this.deleteFreezePeriod(this.freezePeriodToDelete);
      this.freezePeriodToDelete = null;
    },
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
      <template #cell(delete)="{ item }">
        <gl-button
          v-gl-modal="$options.modal.id"
          category="secondary"
          variant="danger"
          icon="remove"
          :aria-label="$options.modal.actionPrimary.text"
          :loading="item.isDeleting"
          data-testid="delete-deploy-freeze"
          @click="handleDeleteFreezePeriod(item)"
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
    <gl-modal
      :title="$options.translations.deleteDeployFreezeTitle"
      :modal-id="$options.modal.id"
      :action-primary="$options.modal.actionPrimary"
      static
      @primary="confirmDeleteFreezePeriod"
    >
      <template v-if="freezePeriodToDelete">
        <gl-sprintf :message="$options.translations.deleteDeployFreezeMessage">
          <template #start>
            <code>{{ freezePeriodToDelete.freezeStart }}</code>
          </template>
          <template #end>
            <code>{{ freezePeriodToDelete.freezeEnd }}</code>
          </template>
          <template #timezone>{{ freezePeriodToDelete.cronTimezone.formattedTimezone }}</template>
        </gl-sprintf>
      </template>
    </gl-modal>
  </div>
</template>
