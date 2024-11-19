<script>
import { GlAlert, GlButton, GlFormCheckbox, GlTooltipDirective } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { s__ } from '~/locale';
import { TYPENAME_DESIGN_VERSION } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { findDesignWidget } from '~/work_items/utils';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import { designArchiveError } from './constants';
import { updateStoreAfterDesignsArchive } from './cache_updates';
import { findVersionId } from './utils';

import getWorkItemDesignListQuery from './graphql/design_collection.query.graphql';
import archiveDesignMutation from './graphql/archive_design.mutation.graphql';
import Design from './design_item.vue';
import DesignVersionDropdown from './design_version_dropdown.vue';
import ArchiveDesignButton from './archive_design_button.vue';

export default {
  components: {
    GlAlert,
    GlButton,
    GlFormCheckbox,
    Design,
    DesignVersionDropdown,
    ArchiveDesignButton,
    CrudComponent,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['fullPath'],
  props: {
    workItemId: {
      type: String,
      required: false,
      default: '',
    },
    workItemIid: {
      type: String,
      required: false,
      default: null,
    },
    uploadError: {
      type: String,
      required: false,
      default: null,
    },
  },
  apollo: {
    designCollection: {
      query: getWorkItemDesignListQuery,
      variables() {
        return {
          id: this.workItemId,
          atVersion: this.designsVersion,
        };
      },
      update(data) {
        const designWidget = findDesignWidget(data.workItem.widgets);
        if (designWidget.designCollection === null) {
          return null;
        }
        const { copyState } = designWidget.designCollection;
        const designNodes = designWidget.designCollection.designs.nodes;
        const versionNodes = designWidget.designCollection.versions.nodes;
        return {
          designs: designNodes,
          copyState,
          versions: versionNodes,
        };
      },
      skip() {
        return !this.workItemId;
      },
      error() {
        this.error = this.$options.i18n.designLoadingError;
      },
    },
  },
  data() {
    return {
      designCollection: null,
      error: null,
      selectedDesigns: [],
      isArchiving: false,
    };
  },
  computed: {
    designs() {
      return this.designCollection?.designs || [];
    },
    allVersions() {
      return this.designCollection?.versions || [];
    },
    hasDesigns() {
      return this.designs.length > 0;
    },
    hasDesignsAndVersions() {
      return this.hasDesigns || this.allVersions.length > 0;
    },
    hasSelectedDesigns() {
      return this.selectedDesigns.length > 0;
    },
    hasValidVersion() {
      return (
        this.$route.query.version &&
        this.allVersions &&
        this.allVersions.some((version) => version.id.endsWith(this.$route.query.version))
      );
    },
    designsVersion() {
      return this.hasValidVersion
        ? convertToGraphQLId(TYPENAME_DESIGN_VERSION, this.$route.query.version)
        : null;
    },
    latestVersionId() {
      const latestVersion = this.allVersions[0];
      return latestVersion && findVersionId(latestVersion.id);
    },
    isLatestVersion() {
      if (this.allVersions.length > 0) {
        return (
          !this.$route.query.version ||
          !this.latestVersionId ||
          this.$route.query.version === this.latestVersionId
        );
      }
      return true;
    },
    designCollectionQueryBody() {
      return {
        query: getWorkItemDesignListQuery,
        variables: { id: this.workItemId, atVersion: null },
      };
    },
    selectAllButtonText() {
      return this.hasSelectedDesigns
        ? s__('DesignManagement|Deselect all')
        : s__('DesignManagement|Select all');
    },
  },
  methods: {
    dismissError() {
      this.error = undefined;
      this.$emit('dismissError');
    },
    isDesignSelected(filename) {
      return this.selectedDesigns.includes(filename);
    },
    checkboxAriaLabel(design) {
      return this.isDesignSelected(design)
        ? s__('DesignManagement|Unselect the design')
        : s__('DesignManagement|Select the design');
    },
    changeSelectedDesigns(filename) {
      if (this.isDesignSelected(filename)) {
        this.selectedDesigns = this.selectedDesigns.filter((design) => design !== filename);
      } else {
        this.selectedDesigns.push(filename);
      }
    },
    toggleDesignsSelection() {
      if (this.hasSelectedDesigns) {
        this.selectedDesigns = [];
      } else {
        this.selectedDesigns = this.designs.map((design) => design.filename);
      }
    },
    async onArchiveDesign() {
      try {
        this.isArchiving = true;
        await this.$apollo.mutate({
          mutation: archiveDesignMutation,
          variables: {
            filenames: this.selectedDesigns,
            projectPath: this.fullPath,
            iid: this.workItemIid,
          },
          update: this.afterArchiveDesign,
        });
      } catch (error) {
        this.error = designArchiveError(this.selectedDesigns.length);
        Sentry.captureException(error);
      } finally {
        // display the latest version
        if (this.$route?.query?.version) {
          this.$router.push({
            path: this.$route.path,
            query: {},
          });
        }
        this.selectedDesigns = [];
        this.isArchiving = false;
      }
    },
    afterArchiveDesign(store, { data: { designManagementDelete } }) {
      updateStoreAfterDesignsArchive(
        store,
        designManagementDelete,
        this.designCollectionQueryBody,
        this.selectedDesigns,
      );
    },
  },
  i18n: {
    designLoadingError: s__(
      'DesignManagement|An error occurred while loading designs. Please try again.',
    ),
    archiveDesignText: s__('DesignManagement|Archive selected'),
    allDesignsArchived: s__('DesignManagement|All designs have been archived.'),
  },
};
</script>

<template>
  <crud-component
    v-if="hasDesignsAndVersions"
    anchor-name="designs"
    anchor-id="designs"
    :title="s__('DesignManagement|Designs')"
    data-testid="designs-root"
    class="gl-mt-5"
    is-collapsible
    persist-collapsed-state
  >
    <template #count>
      <design-version-dropdown :all-versions="allVersions" />
    </template>

    <template #actions>
      <gl-button
        v-if="isLatestVersion"
        category="tertiary"
        class="!gl-text-gray-900"
        size="small"
        variant="link"
        :disabled="!hasDesigns"
        data-testid="select-all-designs-button"
        :aria-label="selectAllButtonText"
        @click="toggleDesignsSelection"
      >
        {{ selectAllButtonText }}
      </gl-button>
      <archive-design-button
        v-if="isLatestVersion"
        data-testid="archive-button"
        button-class="gl-hidden sm:gl-block"
        :has-selected-designs="hasSelectedDesigns"
        :loading="isArchiving"
        @archive-selected-designs="onArchiveDesign"
      >
        {{ $options.i18n.archiveDesignText }}
      </archive-design-button>
      <archive-design-button
        v-if="isLatestVersion"
        v-gl-tooltip.bottom
        data-testid="archive-button"
        button-class="sm:gl-hidden gl-block"
        button-icon="archive"
        :title="$options.i18n.archiveDesignText"
        :aria-label="$options.i18n.archiveDesignText"
        :has-selected-designs="hasSelectedDesigns"
        :loading="isArchiving"
        @archive-selected-designs="onArchiveDesign"
      />
    </template>

    <template #default>
      <gl-alert v-if="error || uploadError" variant="danger" @dismiss="dismissError()">
        {{ error || uploadError }}
      </gl-alert>

      <p v-if="!hasDesigns" class="gl-mb-0 gl-text-subtle">
        {{ $options.i18n.allDesignsArchived }}
      </p>

      <ol v-else class="list-unstyled row -gl-my-1 gl-flex gl-gap-y-5 gl-p-3">
        <li
          v-for="design in designs"
          :key="design.id"
          class="col-md-6 col-lg-3 js-design-tile gl-bg-transparent gl-px-3 gl-shadow-none"
        >
          <design
            v-bind="design"
            class="gl-bg-default"
            :is-uploading="false"
            :work-item-iid="workItemIid"
          />

          <gl-form-checkbox
            v-if="isLatestVersion"
            :checked="isDesignSelected(design.filename)"
            class="gl-absolute gl-left-5 gl-top-4 gl-ml-2"
            data-testid="design-checkbox"
            :aria-label="checkboxAriaLabel(design.filename)"
            @change="changeSelectedDesigns(design.filename)"
          />
        </li>
      </ol>
      <router-view :key="$route.fullPath" :all-designs="designs" />
    </template>
  </crud-component>
</template>
