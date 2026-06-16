<script>
import { GlTable, GlAlert, GlBadge, GlTooltipDirective } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { cloneWithoutReferences } from '~/lib/utils/common_utils';
import { deleteRemoteMirror, syncRemoteMirror, updateRemoteMirror } from '~/api/remote_mirrors_api';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import MirrorActions from './mirror_actions.vue';

export default {
  name: 'MirrorTable',
  components: {
    GlTable,
    GlAlert,
    GlBadge,
    MirrorActions,
    TimeAgoTooltip,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['projectId', 'settingsEnabled', 'repositoryMirrorsAvailable'],
  props: {
    initialMirrors: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      mirrors: cloneWithoutReferences(this.initialMirrors),
      alertMessage: '',
      showAlert: false,
    };
  },
  methods: {
    mirrorBranchesText(item) {
      switch (item.mirrorBranchesSetting) {
        case 'protected':
          return s__('Mirror|All protected branches');
        case 'regex':
          return s__('Mirror|Specific branches');
        default:
          return s__('Mirror|All branches');
      }
    },
    directionText(item) {
      return item.direction === 'pull' ? __('Pull') : __('Push');
    },
    hideAlert() {
      this.showAlert = false;
    },
    showAlertMessage(message) {
      this.alertMessage = message;
      this.showAlert = true;
    },
    findMirror(mirrorId) {
      return this.mirrors.find((m) => m.id === mirrorId);
    },
    onDelete(mirrorId) {
      const previousMirrors = [...this.mirrors];
      this.mirrors = this.mirrors.filter((m) => m.id !== mirrorId);
      if (this.mirrors.length === previousMirrors.length) return;

      deleteRemoteMirror(this.projectId, mirrorId).catch(() => {
        this.mirrors = previousMirrors;
        this.showAlertMessage(s__('Mirror|Failed to remove mirror.'));
      });
    },
    onSync(mirrorId) {
      const mirror = this.findMirror(mirrorId);
      const previousStatus = mirror.updateStatus;
      mirror.updateStatus = 'started';

      syncRemoteMirror(this.projectId, mirrorId).catch(() => {
        mirror.updateStatus = previousStatus;
        this.showAlertMessage(s__('Mirror|Failed to sync mirror.'));
      });
    },
    onToggle(mirrorId) {
      const mirror = this.findMirror(mirrorId);
      const previousEnabled = mirror.enabled;
      const newEnabled = !previousEnabled;
      mirror.enabled = newEnabled;

      updateRemoteMirror(this.projectId, mirrorId, { enabled: newEnabled }).catch(() => {
        mirror.enabled = previousEnabled;
        this.showAlertMessage(
          previousEnabled
            ? s__('Mirror|Failed to disable mirror.')
            : s__('Mirror|Failed to enable mirror.'),
        );
      });
    },
  },
  fields: [
    { key: 'url', label: s__('Mirror|Repository'), tdClass: '!gl-align-middle' },
    { key: 'direction', label: s__('Mirror|Direction'), tdClass: '!gl-align-middle' },
    {
      key: 'lastUpdateStartedAt',
      label: s__('Mirror|Last update attempt'),
      tdClass: '!gl-align-middle',
    },
    {
      key: 'lastUpdateAt',
      label: s__('Mirror|Last successful update'),
      tdClass: '!gl-align-middle',
    },
    { key: 'errorStatus', label: s__('Mirror|Status'), tdClass: '!gl-align-middle' },
    { key: 'actions', label: __('Actions'), thAlignRight: true, tdClass: '!gl-align-middle' },
  ],
  i18n: {
    never: s__('Mirror|Never'),
    disabledTooltip: s__('Mirror|This mirror is disabled and will not sync.'),
    error: s__('Mirror|Error'),
    disabled: s__('Mirror|Disabled'),
    emptyState: __('There are currently no mirrored repositories.'),
  },
};
</script>

<template>
  <div>
    <gl-alert v-if="showAlert" variant="danger" class="gl-mb-4" @dismiss="hideAlert">
      {{ alertMessage }}
    </gl-alert>
    <gl-table :items="mirrors" :fields="$options.fields" stacked="md" show-empty>
      <template #cell(url)="{ item }">
        {{ item.url }}
        <div v-if="repositoryMirrorsAvailable && item.mirrorBranchesSetting" class="gl-mt-3">
          <gl-badge
            v-gl-tooltip
            :title="item.mirrorBranchRegex || ''"
            data-testid="mirror-branches-badge"
          >
            {{ mirrorBranchesText(item) }}
          </gl-badge>
        </div>
      </template>
      <template #cell(direction)="{ item }">
        {{ directionText(item) }}
      </template>
      <template #cell(lastUpdateStartedAt)="{ item }">
        <time-ago-tooltip v-if="item.lastUpdateStartedAt" :time="item.lastUpdateStartedAt" />
        <span v-else>{{ $options.i18n.never }}</span>
      </template>
      <template #cell(lastUpdateAt)="{ item }">
        <time-ago-tooltip v-if="item.lastUpdateAt" :time="item.lastUpdateAt" />
        <span v-else>{{ $options.i18n.never }}</span>
      </template>
      <template #cell(errorStatus)="{ item }">
        <gl-badge
          v-if="!item.enabled"
          v-gl-tooltip
          variant="warning"
          :title="$options.i18n.disabledTooltip"
        >
          {{ $options.i18n.disabled }}
        </gl-badge>
        <gl-badge v-if="item.lastError" v-gl-tooltip variant="danger" :title="item.lastError">
          {{ $options.i18n.error }}
        </gl-badge>
      </template>
      <template #cell(actions)="{ item }">
        <mirror-actions
          v-if="settingsEnabled"
          :mirror="item"
          @sync="onSync(item.id)"
          @toggle="onToggle(item.id)"
          @delete="onDelete(item.id)"
        />
      </template>
      <template #empty>
        <p data-testid="mirror-table-empty-state" class="gl-mb-0 gl-text-center gl-text-subtle">
          {{ $options.i18n.emptyState }}
        </p>
      </template>
    </gl-table>
  </div>
</template>
