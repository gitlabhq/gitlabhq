<script>
import { GlLoadingIcon, GlButton, GlAlert, GlLink, GlSprintf } from '@gitlab/ui';
import VueDraggable from 'vuedraggable';
import permissionsQuery from 'shared_queries/design_management/design_permissions.query.graphql';
import getDesignListQuery from 'shared_queries/design_management/get_design_list.query.graphql';
import createFlash, { FLASH_TYPES } from '~/flash';
import { getFilename } from '~/lib/utils/file_upload';
import { __, s__, sprintf } from '~/locale';
import DesignDropzone from '~/vue_shared/components/upload_dropzone/upload_dropzone.vue';
import DeleteButton from '../components/delete_button.vue';
import DesignDestroyer from '../components/design_destroyer.vue';
import Design from '../components/list/item.vue';
import UploadButton from '../components/upload/button.vue';
import DesignVersionDropdown from '../components/upload/design_version_dropdown.vue';
import { VALID_DESIGN_FILE_MIMETYPE } from '../constants';
import moveDesignMutation from '../graphql/mutations/move_design.mutation.graphql';
import uploadDesignMutation from '../graphql/mutations/upload_design.mutation.graphql';
import allDesignsMixin from '../mixins/all_designs';
import { DESIGNS_ROUTE_NAME } from '../router/constants';
import {
  updateStoreAfterUploadDesign,
  updateDesignsOnStoreAfterReorder,
} from '../utils/cache_update';
import {
  designUploadOptimisticResponse,
  isValidDesignFile,
  moveDesignOptimisticResponse,
} from '../utils/design_management_utils';
import {
  UPLOAD_DESIGN_ERROR,
  EXISTING_DESIGN_DROP_MANY_FILES_MESSAGE,
  EXISTING_DESIGN_DROP_INVALID_FILENAME_MESSAGE,
  MOVE_DESIGN_ERROR,
  UPLOAD_DESIGN_INVALID_FILETYPE_ERROR,
  designUploadSkippedWarning,
  designDeletionError,
} from '../utils/error_messages';
import { trackDesignCreate, trackDesignUpdate } from '../utils/tracking';

const MAXIMUM_FILE_UPLOAD_LIMIT = 10;

export default {
  components: {
    GlLoadingIcon,
    GlAlert,
    GlButton,
    GlSprintf,
    GlLink,
    UploadButton,
    Design,
    DesignDestroyer,
    DesignVersionDropdown,
    DeleteButton,
    DesignDropzone,
    VueDraggable,
  },
  dropzoneProps: {
    dropToStartMessage: __('Drop your designs to start your upload.'),
    isFileValid: isValidDesignFile,
    validFileMimetypes: [VALID_DESIGN_FILE_MIMETYPE.mimetype],
  },
  mixins: [allDesignsMixin],
  apollo: {
    permissions: {
      query: permissionsQuery,
      variables() {
        return {
          fullPath: this.projectPath,
          iid: this.issueIid,
        };
      },
      update: (data) => data.project.issue.userPermissions,
    },
  },
  beforeRouteUpdate(to, from, next) {
    this.selectedDesigns = [];
    next();
  },
  data() {
    return {
      permissions: {
        createDesign: false,
      },
      filesToBeSaved: [],
      selectedDesigns: [],
      isDraggingDesign: false,
      reorderedDesigns: null,
      isReorderingInProgress: false,
    };
  },
  computed: {
    isLoading() {
      return (
        this.$apollo.queries.designCollection.loading || this.$apollo.queries.permissions.loading
      );
    },
    isSaving() {
      return this.filesToBeSaved.length > 0;
    },
    canCreateDesign() {
      return this.permissions.createDesign;
    },
    showToolbar() {
      return this.canCreateDesign && this.allVersions.length > 0;
    },
    hasDesigns() {
      return this.designs.length > 0;
    },
    hasSelectedDesigns() {
      return this.selectedDesigns.length > 0;
    },
    canDeleteDesigns() {
      return this.isLatestVersion && this.hasSelectedDesigns;
    },
    projectQueryBody() {
      return {
        query: getDesignListQuery,
        variables: { fullPath: this.projectPath, iid: this.issueIid, atVersion: null },
      };
    },
    selectAllButtonText() {
      return this.hasSelectedDesigns
        ? s__('DesignManagement|Deselect all')
        : s__('DesignManagement|Select all');
    },
    isDesignListEmpty() {
      return !this.isSaving && !this.hasDesigns;
    },
    isDesignCollectionCopying() {
      return this.designCollection && this.designCollection.copyState === 'IN_PROGRESS';
    },
    designDropzoneWrapperClass() {
      return this.isDesignListEmpty
        ? 'col-12'
        : 'gl-flex-direction-column col-md-6 col-lg-3 gl-mb-3';
    },
  },
  mounted() {
    if (this.$route.path === '/designs') {
      this.$el.scrollIntoView();
    }
  },
  methods: {
    resetFilesToBeSaved() {
      this.filesToBeSaved = [];
    },
    /**
     * Determine if a design upload is valid, given [files]
     * @param {Array<File>} files
     */
    isValidDesignUpload(files) {
      if (!this.canCreateDesign) return false;

      if (files.length > MAXIMUM_FILE_UPLOAD_LIMIT) {
        createFlash({
          message: sprintf(
            s__(
              'DesignManagement|The maximum number of designs allowed to be uploaded is %{upload_limit}. Please try again.',
            ),
            {
              upload_limit: MAXIMUM_FILE_UPLOAD_LIMIT,
            },
          ),
        });

        return false;
      }
      return true;
    },
    onUploadDesign(files) {
      // convert to Array so that we have Array methods (.map, .some, etc.)
      this.filesToBeSaved = Array.from(files);
      if (!this.isValidDesignUpload(this.filesToBeSaved)) return null;

      const mutationPayload = {
        optimisticResponse: designUploadOptimisticResponse(this.filesToBeSaved),
        variables: {
          files: this.filesToBeSaved,
          projectPath: this.projectPath,
          iid: this.issueIid,
        },
        context: {
          hasUpload: true,
        },
        mutation: uploadDesignMutation,
        update: this.afterUploadDesign,
      };

      return this.$apollo
        .mutate(mutationPayload)
        .then((res) => this.onUploadDesignDone(res))
        .catch(() => this.onUploadDesignError());
    },
    afterUploadDesign(store, { data: { designManagementUpload } }) {
      updateStoreAfterUploadDesign(store, designManagementUpload, this.projectQueryBody);
    },
    onUploadDesignDone(res) {
      // display any warnings, if necessary
      const skippedFiles = res?.data?.designManagementUpload?.skippedDesigns || [];
      const skippedWarningMessage = designUploadSkippedWarning(this.filesToBeSaved, skippedFiles);
      if (skippedWarningMessage) {
        createFlash({ message: skippedWarningMessage, types: FLASH_TYPES.WARNING });
      }

      // if this upload resulted in a new version being created, redirect user to the latest version
      if (!this.isLatestVersion) {
        this.$router.push({ name: DESIGNS_ROUTE_NAME });
      }

      // reset state
      this.resetFilesToBeSaved();
      this.trackUploadDesign(res);
    },
    trackUploadDesign(res) {
      (res?.data?.designManagementUpload?.designs || []).forEach((design) => {
        if (design.event === 'CREATION') {
          trackDesignCreate();
        } else if (design.event === 'MODIFICATION') {
          trackDesignUpdate();
        }
      });
    },
    onUploadDesignError() {
      this.resetFilesToBeSaved();
      createFlash({ message: UPLOAD_DESIGN_ERROR });
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
    isDesignSelected(filename) {
      return this.selectedDesigns.includes(filename);
    },
    isDesignToBeSaved(filename) {
      return this.filesToBeSaved.some((file) => file.name === filename);
    },
    canSelectDesign(filename) {
      return this.isLatestVersion && this.canCreateDesign && !this.isDesignToBeSaved(filename);
    },
    onDesignDelete() {
      this.selectedDesigns = [];
      if (this.$route.query.version) this.$router.push({ name: DESIGNS_ROUTE_NAME });
    },
    onDesignDeleteError() {
      const errorMessage = designDeletionError({ singular: this.selectedDesigns.length === 1 });
      createFlash({ message: errorMessage });
    },
    onDesignDropzoneError() {
      createFlash({ message: UPLOAD_DESIGN_INVALID_FILETYPE_ERROR });
    },
    onExistingDesignDropzoneChange(files, existingDesignFilename) {
      const filesArr = Array.from(files);

      if (filesArr.length > 1) {
        createFlash({ message: EXISTING_DESIGN_DROP_MANY_FILES_MESSAGE });
        return;
      }

      if (!filesArr.some(({ name }) => existingDesignFilename === name)) {
        createFlash({ message: EXISTING_DESIGN_DROP_INVALID_FILENAME_MESSAGE });
        return;
      }

      this.onUploadDesign(files);
    },
    onDesignPaste(event) {
      const { clipboardData } = event;
      const files = Array.from(clipboardData.files);
      if (clipboardData && files.length > 0) {
        if (!files.some(isValidDesignFile)) {
          return;
        }
        event.preventDefault();
        let filename = getFilename(event);
        if (!filename || filename === 'image.png') {
          filename = `design_${Date.now()}.png`;
        }
        const newFile = new File([files[0]], filename);
        this.onUploadDesign([newFile]);
      }
    },
    toggleOnPasteListener() {
      document.addEventListener('paste', this.onDesignPaste);
    },
    toggleOffPasteListener() {
      document.removeEventListener('paste', this.onDesignPaste);
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
    reorderDesigns({ moved: { newIndex, element } }) {
      this.isReorderingInProgress = true;
      this.$apollo
        .mutate({
          mutation: moveDesignMutation,
          variables: this.designMoveVariables(newIndex, element),
          update: (store, { data: { designManagementMove } }) =>
            updateDesignsOnStoreAfterReorder(store, designManagementMove, this.projectQueryBody),
          optimisticResponse: moveDesignOptimisticResponse(this.reorderedDesigns),
        })
        .catch(() => {
          createFlash({ message: MOVE_DESIGN_ERROR });
        })
        .finally(() => {
          this.isReorderingInProgress = false;
        });
    },
    onDesignMove(designs) {
      this.reorderedDesigns = designs;
    },
  },
  dragOptions: {
    animation: 200,
    ghostClass: 'gl-visibility-hidden',
  },
  i18n: {
    dropzoneDescriptionText: __('Drag your designs here or %{linkStart}click to upload%{linkEnd}.'),
  },
};
</script>

<template>
  <div
    data-testid="designs-root"
    class="gl-mt-5"
    @mouseenter="toggleOnPasteListener"
    @mouseleave="toggleOffPasteListener"
  >
    <header
      v-if="showToolbar"
      class="row-content-block gl-border-t-0 gl-py-3 gl-display-flex"
      data-testid="design-toolbar-wrapper"
    >
      <div
        class="gl-display-flex gl-justify-content-space-between gl-align-items-center gl-w-full gl-flex-wrap"
      >
        <div class="gl-display-flex gl-align-items-center gl-my-2">
          <span class="gl-font-weight-bold gl-mr-3">{{ s__('DesignManagement|Designs') }}</span>
          <design-version-dropdown />
        </div>
        <div
          v-show="hasDesigns"
          class="qa-selector-toolbar gl-display-flex gl-align-items-center gl-my-2"
        >
          <gl-button
            v-if="isLatestVersion"
            variant="link"
            size="small"
            class="gl-mr-3"
            data-testid="select-all-designs-button"
            @click="toggleDesignsSelection"
            >{{ selectAllButtonText }}
          </gl-button>
          <design-destroyer
            #default="{ mutate, loading }"
            :filenames="selectedDesigns"
            @done="onDesignDelete"
            @error="onDesignDeleteError"
          >
            <delete-button
              v-if="isLatestVersion"
              :is-deleting="loading"
              button-variant="default"
              button-class="gl-mr-3"
              button-size="small"
              data-qa-selector="archive_button"
              :loading="loading"
              :has-selected-designs="hasSelectedDesigns"
              @delete-selected-designs="mutate()"
            >
              {{ s__('DesignManagement|Archive selected') }}
            </delete-button>
          </design-destroyer>
          <upload-button
            v-if="canCreateDesign"
            :is-saving="isSaving"
            data-testid="design-upload-button"
            @upload="onUploadDesign"
          />
        </div>
      </div>
    </header>
    <div class="gl-mt-6">
      <gl-loading-icon v-if="isLoading" size="md" />
      <gl-alert v-else-if="error" variant="danger" :dismissible="false">
        {{ __('An error occurred while loading designs. Please try again.') }}
      </gl-alert>
      <header
        v-else-if="isDesignCollectionCopying"
        class="card"
        data-testid="design-collection-is-copying"
      >
        <div class="card-header design-card-header gl-border-b-0">
          <div class="card-title gl-display-flex gl-align-items-center gl-my-0 gl-h-7">
            {{
              s__(
                'DesignManagement|Your designs are being copied and are on their way… Please refresh to update.',
              )
            }}
          </div>
        </div>
      </header>
      <vue-draggable
        v-else
        :value="designs"
        :disabled="!isLatestVersion || isReorderingInProgress"
        v-bind="$options.dragOptions"
        tag="ol"
        draggable=".js-design-tile"
        class="list-unstyled row"
        @start="isDraggingDesign = true"
        @end="isDraggingDesign = false"
        @change="reorderDesigns"
        @input="onDesignMove"
      >
        <li
          v-for="design in designs"
          :key="design.id"
          class="col-md-6 col-lg-3 gl-mb-3 gl-bg-transparent gl-shadow-none js-design-tile"
        >
          <design-dropzone
            :display-as-card="hasDesigns"
            :enable-drag-behavior="isDraggingDesign"
            v-bind="$options.dropzoneProps"
            @change="onExistingDesignDropzoneChange($event, design.filename)"
            @error="onDesignDropzoneError"
          >
            <design
              v-bind="design"
              :is-uploading="isDesignToBeSaved(design.filename)"
              class="gl-bg-white"
            />
            <template #upload-text="{ openFileUpload }">
              <gl-sprintf :message="$options.i18n.dropzoneDescriptionText">
                <template #link="{ content }">
                  <gl-link @click.stop="openFileUpload">
                    {{ content }}
                  </gl-link>
                </template>
              </gl-sprintf>
            </template>
          </design-dropzone>

          <input
            v-if="canSelectDesign(design.filename)"
            :checked="isDesignSelected(design.filename)"
            type="checkbox"
            class="design-checkbox"
            data-qa-selector="design_checkbox"
            :data-qa-design="design.filename"
            @change="changeSelectedDesigns(design.filename)"
          />
        </li>
        <template #header>
          <li :class="designDropzoneWrapperClass" data-testid="design-dropzone-wrapper">
            <design-dropzone
              :enable-drag-behavior="isDraggingDesign"
              :class="{ 'design-list-item design-list-item-new': !isDesignListEmpty }"
              :display-as-card="hasDesigns"
              v-bind="$options.dropzoneProps"
              data-qa-selector="design_dropzone_content"
              @change="onUploadDesign"
              @error="onDesignDropzoneError"
            >
              <template #upload-text="{ openFileUpload }">
                <gl-sprintf :message="$options.i18n.dropzoneDescriptionText">
                  <template #link="{ content }">
                    <gl-link @click.stop="openFileUpload">{{ content }}</gl-link>
                  </template>
                </gl-sprintf>
              </template>
            </design-dropzone>
          </li>
        </template>
      </vue-draggable>
    </div>
    <router-view :key="$route.fullPath" />
  </div>
</template>
