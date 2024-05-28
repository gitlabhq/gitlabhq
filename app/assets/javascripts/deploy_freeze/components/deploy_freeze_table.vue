<script>
import {
  GlCard,
  GlTable,
  GlButton,
  GlIcon,
  GlModal,
  GlModalDirective,
  GlSprintf,
} from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapActions } from 'vuex';
import { __, s__ } from '~/locale';

export default {
  fields: [
    {
      key: 'freezeStart',
      label: s__('DeployFreeze|Freeze start'),
      tdClass: '!gl-align-middle',
    },
    {
      key: 'freezeEnd',
      label: s__('DeployFreeze|Freeze end'),
      tdClass: '!gl-align-middle',
    },
    {
      key: 'cronTimezone',
      label: s__('DeployFreeze|Time zone'),
      tdClass: '!gl-align-middle',
    },
    {
      key: 'actions',
      label: __('Actions'),
      thClass: 'gl-text-right',
    },
  ],
  i18n: {
    title: s__('DeployFreeze|Deploy freezes'),
    addDeployFreeze: s__('DeployFreeze|Add deploy freeze'),
    deleteDeployFreezeTitle: s__('DeployFreeze|Delete deploy freeze?'),
    deleteDeployFreezeMessage: s__(
      'DeployFreeze|Deploy freeze from %{start} to %{end} in %{timezone} will be removed. Are you sure?',
    ),
    emptyStateText: s__(
      'DeployFreeze|No deploy freezes exist for this project. To add one, select %{strongStart}Add deploy freeze%{strongEnd} above.',
    ),
  },
  modal: {
    id: 'deleteFreezePeriodModal',
    actionPrimary: {
      text: s__('DeployFreeze|Delete freeze period'),
      attributes: { variant: 'danger', 'data-testid': 'modal-confirm' },
    },
    actionSecondary: {
      text: __('Cancel'),
      attributes: { variant: 'default' },
    },
  },
  components: {
    GlCard,
    GlTable,
    GlButton,
    GlIcon,
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
  <gl-card
    class="gl-new-card deploy-freeze-table"
    header-class="gl-new-card-header"
    body-class="gl-new-card-body gl-px-0"
  >
    <template #header>
      <div class="gl-new-card-title-wrapper">
        <h3 class="gl-new-card-title">{{ $options.i18n.title }}</h3>
        <span class="gl-new-card-count">
          <gl-icon name="deployments" class="gl-mr-2" />
          {{ freezePeriods.length }}
        </span>
      </div>
      <div class="gl-new-card-actions">
        <gl-button v-gl-modal.deploy-freeze-modal size="small" data-testid="add-deploy-freeze">{{
          $options.i18n.addDeployFreeze
        }}</gl-button>
      </div>
    </template>

    <gl-table
      data-testid="deploy-freeze-table"
      :items="freezePeriods"
      :fields="$options.fields"
      show-empty
      stacked="md"
    >
      <template #cell(cronTimezone)="{ item }">
        {{ item.cronTimezone.formattedTimezone }}
      </template>
      <template #cell(actions)="{ item }">
        <div class="gl-display-flex gl-justify-content-end -gl-mt-2 -gl-mb-2">
          <gl-button
            v-gl-modal.deploy-freeze-modal
            icon="pencil"
            data-testid="edit-deploy-freeze"
            :aria-label="__('Edit deploy freeze')"
            class="gl-mr-3"
            @click="setFreezePeriod(item)"
          />
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
        </div>
      </template>
      <template #empty>
        <p data-testid="empty-freeze-periods" class="gl-text-secondary gl-text-center gl-mb-0">
          <gl-sprintf :message="$options.i18n.emptyStateText">
            <template #strong="{ content }">
              {{ content }}
            </template>
          </gl-sprintf>
        </p>
      </template>
    </gl-table>
    <gl-modal
      :title="$options.i18n.deleteDeployFreezeTitle"
      :modal-id="$options.modal.id"
      :action-primary="$options.modal.actionPrimary"
      :action-secondary="$options.modal.actionSecondary"
      static
      @primary="confirmDeleteFreezePeriod"
    >
      <template v-if="freezePeriodToDelete">
        <gl-sprintf :message="$options.i18n.deleteDeployFreezeMessage">
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
  </gl-card>
</template>
