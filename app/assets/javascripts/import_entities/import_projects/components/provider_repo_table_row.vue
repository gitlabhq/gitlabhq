<script>
import { GlIcon, GlBadge, GlFormInput, GlButton, GlLink, GlTooltip, GlSprintf } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapGetters, mapActions } from 'vuex';
import { __ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import HelpPopover from '~/vue_shared/components/help_popover.vue';
import ImportTargetDropdown from '../../components/import_target_dropdown.vue';
import ImportStatus from '../../components/import_status.vue';
import { STATUSES } from '../../constants';
import { isProjectImportable, isImporting, isIncompatible, getImportStatus } from '../utils';

export default {
  name: 'ProviderRepoTableRow',
  components: {
    HelpPopover,
    ImportStatus,
    ImportTargetDropdown,
    GlFormInput,
    GlButton,
    GlIcon,
    GlBadge,
    GlLink,
    GlTooltip,
    GlSprintf,
  },
  inject: {
    userNamespace: {
      default: null,
    },
  },
  props: {
    repo: {
      type: Object,
      required: true,
    },
    optionalStages: {
      type: Object,
      required: true,
    },
    cancelable: {
      type: Boolean,
      required: false,
      default: false,
    },
  },

  data() {
    return {
      isSelectedForReimport: false,
    };
  },

  computed: {
    ...mapState(['ciCdOnly']),
    ...mapGetters(['getImportTarget']),

    displayFullPath() {
      return this.repo.importedProject?.fullPath.replace(/^\//, '');
    },

    showMembershipsWarning() {
      const userNamespaceSelected = this.importTarget.targetNamespace === this.userNamespace;
      return this.isImportNotStarted && userNamespaceSelected;
    },

    isFinished() {
      return this.repo.importedProject?.importStatus === STATUSES.FINISHED;
    },

    isImportNotStarted() {
      return isProjectImportable(this.repo);
    },

    isIncompatible() {
      return isIncompatible(this.repo);
    },

    importStatus() {
      return getImportStatus(this.repo);
    },

    isImporting() {
      return isImporting(this.repo);
    },

    isCancelable() {
      return this.cancelable && this.isImporting && this.importStatus !== STATUSES.SCHEDULING;
    },

    stats() {
      return this.repo.importedProject?.stats;
    },

    importTarget() {
      return this.getImportTarget(this.repo.importSource.id);
    },

    importedProjectId() {
      return this.repo.importedProject?.id;
    },

    importButtonText() {
      if (this.ciCdOnly) {
        return __('Connect');
      }

      return this.isFinished ? __('Re-import') : __('Import');
    },

    newNameInput: {
      get() {
        return this.importTarget.newName;
      },
      set(value) {
        this.updateImportTarget({ newName: value });
      },
    },
  },

  methods: {
    ...mapActions(['fetchImport', 'cancelImport', 'setImportTarget']),
    updateImportTarget(changedValues) {
      this.setImportTarget({
        repoId: this.repo.importSource.id,
        importTarget: { ...this.importTarget, ...changedValues },
      });
    },

    handleImportRepo() {
      if (this.isFinished && !this.isSelectedForReimport) {
        this.isSelectedForReimport = true;
        this.$nextTick(() => {
          this.$refs.newNameInput.$el.focus();
        });
      } else {
        this.isSelectedForReimport = false;

        this.fetchImport({
          repoId: this.repo.importSource.id,
          optionalStages: this.optionalStages,
        });
      }
    },

    onSelect(value) {
      this.updateImportTarget({ targetNamespace: value });
    },
  },

  helpPath: helpPagePath('/user/project/import/github'),
  membershipsHelpPath: helpPagePath('user/project/import/_index', {
    anchor: 'user-contribution-and-membership-mapping',
  }),
};
</script>

<template>
  <tr
    class="gl-h-11"
    data-testid="project-import-row"
    :data-qa-source-project="repo.importSource.fullName"
  >
    <td>
      <gl-link :href="repo.importSource.providerLink" target="_blank" data-testid="provider-link"
        >{{ repo.importSource.fullName }}
        <gl-icon
          v-if="repo.importSource.providerLink"
          name="external-link"
          class="gl-fill-icon-link"
        />
      </gl-link>
      <div v-if="isFinished" class="gl-mt-2 gl-text-sm">
        <gl-sprintf :message="s__('BulkImport|Last imported to %{link}')">
          <template #link>
            <gl-link
              :href="repo.importedProject.fullPath"
              class="gl-text-sm"
              target="_blank"
              data-testid="go-to-project-link"
            >
              {{ displayFullPath }}
            </gl-link>
          </template>
        </gl-sprintf>
      </div>
    </td>
    <td data-testid="fullPath">
      <div class="gl-flex sm:gl-flex-wrap">
        <template v-if="repo.importSource.target">{{ repo.importSource.target }}</template>
        <template v-else-if="isImportNotStarted || isSelectedForReimport">
          <div class="gl-flex gl-w-full gl-items-stretch">
            <import-target-dropdown
              :selected="importTarget.targetNamespace"
              :user-namespace="userNamespace"
              @select="onSelect"
            />
            <div
              class="gl-flex gl-items-center gl-border-0 gl-border-b-1 gl-border-t-1 gl-border-solid gl-border-strong gl-px-3"
            >
              /
            </div>
            <gl-form-input
              ref="newNameInput"
              v-model="newNameInput"
              class="gl-rounded-bl-none gl-rounded-tl-none !gl-shadow-inner-1-border-strong"
              data-testid="project-path-field"
            />
          </div>
        </template>
        <template v-else-if="repo.importedProject">{{ displayFullPath }}</template>
      </div>
    </td>
    <td data-testid="import-status-indicator">
      <import-status :project-id="importedProjectId" :status="importStatus" :stats="stats" />
    </td>
    <td data-testid="actions" class="gl-whitespace-nowrap">
      <gl-tooltip :target="() => $refs.cancelButton.$el">
        <div class="gl-text-left">
          <p class="gl-mb-5 gl-font-bold">{{ s__('ImportProjects|Cancel import') }}</p>
          {{
            s__(
              'ImportProjects|Imported files will be kept. You can import this repository again later.',
            )
          }}
          <gl-link :href="$options.helpPath" target="_blank">{{ __('Learn more.') }}</gl-link>
        </div>
      </gl-tooltip>
      <gl-button
        v-show="isCancelable"
        ref="cancelButton"
        variant="danger"
        category="secondary"
        icon="cancel"
        :aria-label="__('Cancel')"
        @click="cancelImport({ repoId: repo.importSource.id })"
      />
      <gl-button
        v-if="isImportNotStarted || isFinished"
        type="button"
        data-testid="import-button"
        @click="handleImportRepo()"
      >
        {{ importButtonText }}
      </gl-button>
      <span class="gl-ml-3 gl-inline-flex gl-gap-3">
        <help-popover
          v-show="showMembershipsWarning"
          icon="warning"
          trigger-class="!gl-text-warning"
          data-testid="memberships-warning"
        >
          {{
            s__(
              'ImportProjects|Importing a project into a personal namespace results in all contributions being mapped to the same bot user. To map contributions to real users, import projects into a group instead.',
            )
          }}
          <gl-link :href="$options.membershipsHelpPath" target="_blank">{{
            __('Learn more.')
          }}</gl-link>
        </help-popover>

        <help-popover v-if="isFinished" icon="information-o">
          {{
            s__(
              'ImportProjects|Re-import creates a new project. It does not sync with the existing project.',
            )
          }}
        </help-popover>
        <gl-badge v-else-if="isIncompatible" variant="danger">{{
          __('Incompatible project')
        }}</gl-badge>
      </span>
    </td>
  </tr>
</template>
