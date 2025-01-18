<script>
import { GlAlert, GlButton, GlFormCheckbox, GlTooltipDirective } from '@gitlab/ui';
import { GlBreakpointInstance } from '@gitlab/ui/dist/utils';
import VueDraggable from 'vuedraggable';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { s__ } from '~/locale';
import { isLoggedIn } from '~/lib/utils/common_utils';
import { TYPENAME_DESIGN_VERSION } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { findDesignWidget } from '~/work_items/utils';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import DesignDropzone from '~/vue_shared/components/upload_dropzone/upload_dropzone.vue';
import {
  designArchiveError,
  VALID_DESIGN_FILE_MIMETYPE,
  ALERT_VARIANTS,
  MOVE_DESIGN_ERROR,
} from './constants';
import { updateStoreAfterDesignsArchive, updateDesignsOnStoreAfterReorder } from './cache_updates';
import { findVersionId, moveDesignOptimisticResponse } from './utils';

import getWorkItemDesignListQuery from './graphql/design_collection.query.graphql';
import archiveDesignMutation from './graphql/archive_design.mutation.graphql';
import moveDesignMutation from './graphql/move_design.mutation.graphql';
import Design from './design_item.vue';
import DesignVersionDropdown from './design_version_dropdown.vue';
import ArchiveDesignButton from './archive_design_button.vue';

export default {
  isLoggedIn: isLoggedIn(),
  components: {
    GlAlert,
    GlButton,
    GlFormCheckbox,
    Design,
    DesignVersionDropdown,
    ArchiveDesignButton,
    CrudComponent,
    DesignDropzone,
    VueDraggable,
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
    isSaving: {
      type: Boolean,
      required: false,
      default: false,
    },
    uploadError: {
      type: String,
      required: false,
      default: null,
    },
    uploadErrorVariant: {
      type: String,
      required: false,
      default: ALERT_VARIANTS.danger,
    },
    canReorderDesign: {
      type: Boolean,
      required: false,
      default: false,
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
      isDraggingDesign: false,
      reorderedDesigns: null,
      isReorderingInProgress: false,
      dragStartPosition: null,
    };
  },
  computed: {
    isMobile() {
      return ['sm', 'xs'].includes(GlBreakpointInstance.getBreakpointSize());
    },
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
    /**
     * This is needed to increase size of dropzone when all
     * designs are archived and only empty state is visible.
     */
    crudBodyClass() {
      return this.hasDesigns ? '' : '!gl-m-0';
    },
    designsVersion() {
      return this.hasValidVersion
        ? convertToGraphQLId(TYPENAME_DESIGN_VERSION, this.$route.query.version)
        : null;
    },
    isDraggingDisabled() {
      return (
        !this.$options.isLoggedIn ||
        !this.isLatestVersion ||
        !this.canReorderDesign ||
        this.isReorderingInProgress ||
        this.isMobile
      );
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
    openDesignUpload() {
      this.$refs.fileUpload.click();
    },
    onDesignUploadChange(e) {
      this.$emit('upload', e.target.files);
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
    designMoveVariables(newIndex, element) {
      const variables = {
        id: element.id,
      };
      if (newIndex > 0) {
        variables.previous = this.reorderedDesigns[newIndex - 1].id;
      }
      if (newIndex < this.reorderedDesigns.length - 1) {
        variables.next = this.reorderedDesigns[newIndex + 1].id;
      }
      return variables;
    },
    async onDesignsReorder({ moved: { newIndex, element } }) {
      this.isReorderingInProgress = true;
      try {
        await this.$apollo.mutate({
          mutation: moveDesignMutation,
          variables: this.designMoveVariables(newIndex, element),
          update: this.afterReorderDesign,
          optimisticResponse: moveDesignOptimisticResponse(this.reorderedDesigns),
        });
      } catch (error) {
        this.error = MOVE_DESIGN_ERROR;
        Sentry.captureException(error);
      } finally {
        this.isReorderingInProgress = false;
      }
    },
    afterReorderDesign(store, { data: { designManagementMove } }) {
      updateDesignsOnStoreAfterReorder(store, designManagementMove, this.designCollectionQueryBody);
    },
    onDesignMove(designs) {
      this.reorderedDesigns = designs;
    },
    onMouseDown({ clientX, clientY }) {
      this.dragStartPosition = { x: clientX, y: clientY };
    },
    onPointerUp(event) {
      const { clientX, clientY } = event;
      const deltaX = Math.abs(clientX - this.dragStartPosition.x);
      const deltaY = Math.abs(clientY - this.dragStartPosition.y);

      // Checking if the mouse movement was below the drag threshold of 5px
      // to treat the event as a click, not a drag
      if (deltaX < 5 && deltaY < 5) {
        // Envoking click event since VueDraggable suppresses it intermittently
        event.target.click();
        this.isDraggingDesign = false;

        // Tackling Chrome specific issues of VueDraggable not propagating
        // the click to children
        if (event.target.tagName === 'OL') {
          const designTiles = event.target.querySelectorAll('.js-design-tile');
          // Finding the tile under the <ol> tag pointer
          const hoveredTile = Array.from(designTiles).find((tile) => {
            const { top, left, right, bottom } = tile.getBoundingClientRect();
            return clientX >= left && clientX <= right && clientY >= top && clientY <= bottom;
          });
          if (hoveredTile) {
            const designLink = hoveredTile.querySelector('.design-list-item');
            designLink.click();
          }
        }
      } else {
        this.isDraggingDesign = true;
      }
      this.lastDragPosition = null;
    },
    onDragEnd() {
      // Deffering setting the flag to false so that the tile
      // click is not fired right after drag ends
      setTimeout(() => {
        this.isDraggingDesign = false;
      }, 100);
    },
  },
  dragOptions: {
    animation: 200,
    ghostClass: 'gl-invisible',
    forceFallback: true,
    tag: 'ol',
    filter: '.no-drag',
    draggable: '.js-design-tile',
  },
  i18n: {
    designLoadingError: s__(
      'DesignManagement|An error occurred while loading designs. Please try again.',
    ),
    archiveDesignText: s__('DesignManagement|Archive selected'),
    allDesignsArchived: s__('DesignManagement|All designs have been archived.'),
    uploadDesignOverlayText: s__('DesignManagement|Drop your images to start the upload.'),
  },
  VALID_DESIGN_FILE_MIMETYPE,
};
</script>

<template>
  <div>
    <slot v-if="!hasDesignsAndVersions" name="empty-state"></slot>
    <crud-component
      v-if="hasDesignsAndVersions"
      anchor-name="designs"
      anchor-id="designs"
      :title="s__('DesignManagement|Designs')"
      data-testid="designs-root"
      class="gl-relative gl-mt-5"
      :body-class="crudBodyClass"
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
        <gl-button
          size="small"
          data-testid="add-design"
          :disabled="isSaving"
          :loading="isSaving"
          @click="openDesignUpload"
          >{{ __('Add') }}</gl-button
        >
        <input
          ref="fileUpload"
          type="file"
          name="design_file"
          :accept="$options.VALID_DESIGN_FILE_MIMETYPE.mimetype"
          class="gl-hidden"
          multiple
          @change="onDesignUploadChange"
        />
      </template>

      <template #default>
        <gl-alert
          v-if="error || uploadError"
          :variant="uploadErrorVariant"
          @dismiss="dismissError()"
        >
          {{ error || uploadError }}
        </gl-alert>
        <design-dropzone
          show-upload-design-overlay
          validate-design-upload-on-dragover
          :accept-design-formats="$options.VALID_DESIGN_FILE_MIMETYPE.mimetype"
          :upload-design-overlay-text="$options.i18n.uploadDesignOverlayText"
          @change="$emit('upload', $event)"
          @error="$emit('error')"
          @dragenter="dismissError"
        >
          <p v-if="!hasDesigns" class="gl-mb-0 gl-px-5 gl-py-4 gl-text-subtle">
            {{ $options.i18n.allDesignsArchived }}
          </p>
          <vue-draggable
            :value="designs"
            :disabled="isDraggingDisabled"
            v-bind="$options.dragOptions"
            class="list-unstyled row -gl-my-1 gl-flex gl-gap-y-5"
            :class="{ 'gl-px-3 gl-py-2': hasDesigns, 'gl-hidden': !hasDesigns }"
            @end="onDragEnd"
            @change="onDesignsReorder"
            @input="onDesignMove"
            @pointerup.native="onPointerUp"
          >
            <li
              v-for="design in designs"
              :key="design.id"
              class="col-md-6 col-lg-3 js-design-tile gl-bg-transparent gl-px-3 gl-shadow-none"
              @mousedown="onMouseDown"
              @pointerup="onPointerUp"
            >
              <design
                v-bind="design"
                class="gl-bg-default"
                :is-uploading="false"
                :is-dragging="isDraggingDesign"
                :work-item-iid="workItemIid"
                data-testid="design-item"
                @pointerup="onPointerUp"
              />

              <gl-form-checkbox
                v-if="isLatestVersion"
                :id="`design-checkbox-${design.id}`"
                :checked="isDesignSelected(design.filename)"
                class="no-drag gl-absolute gl-left-5 gl-top-4 gl-ml-2"
                data-testid="design-checkbox"
                :aria-label="checkboxAriaLabel(design.filename)"
                @change="changeSelectedDesigns(design.filename)"
              />
            </li>
          </vue-draggable>
        </design-dropzone>
        <router-view :key="$route.fullPath" :all-designs="designs" :all-versions="allVersions" />
      </template>
    </crud-component>
  </div>
</template>
