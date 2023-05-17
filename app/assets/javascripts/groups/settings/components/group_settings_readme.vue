<script>
import { GlButton, GlModal, GlModalDirective, GlSprintf } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import { createProject } from '~/rest_api';
import { createAlert } from '~/alert';
import { openWebIDE } from '~/lib/utils/web_ide_navigator';
import { README_MODAL_ID, GITLAB_README_PROJECT, README_FILE } from '../constants';

export default {
  name: 'GroupSettingsReadme',
  i18n: {
    readme: __('README'),
    addReadme: __('Add README'),
    cancel: __('Cancel'),
    createProjectAndReadme: s__('Groups|Create and add README'),
    creatingReadme: s__('Groups|Creating README'),
    existingProjectNewReadme: s__('Groups|This will create a README.md for project %{path}.'),
    newProjectAndReadme: s__('Groups|This will create a project %{path} and add a README.md.'),
    errorCreatingProject: s__('Groups|There was an error creating the Group README.'),
  },
  components: {
    GlButton,
    GlModal,
    GlSprintf,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  props: {
    groupReadmePath: {
      type: String,
      required: false,
      default: '',
    },
    readmeProjectPath: {
      type: String,
      required: false,
      default: '',
    },
    groupPath: {
      type: String,
      required: true,
    },
    groupId: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      creatingReadme: false,
    };
  },
  computed: {
    hasReadme() {
      return this.groupReadmePath.length > 0;
    },
    hasReadmeProject() {
      return this.readmeProjectPath.length > 0;
    },
    pathToReadmeProject() {
      return this.hasReadmeProject
        ? this.readmeProjectPath
        : `${this.groupPath}/${GITLAB_README_PROJECT}`;
    },
    modalBody() {
      return this.hasReadmeProject
        ? this.$options.i18n.existingProjectNewReadme
        : this.$options.i18n.newProjectAndReadme;
    },
    modalSubmitButtonText() {
      return this.hasReadmeProject
        ? this.$options.i18n.addReadme
        : this.$options.i18n.createProjectAndReadme;
    },
  },
  methods: {
    hideModal() {
      this.$refs.modal.hide();
    },
    createReadme() {
      if (this.hasReadmeProject) {
        openWebIDE(this.readmeProjectPath, README_FILE);
      } else {
        this.createProjectWithReadme();
      }
    },
    createProjectWithReadme() {
      this.creatingReadme = true;

      const projectData = {
        name: GITLAB_README_PROJECT,
        namespace_id: this.groupId,
      };

      createProject(projectData)
        .then(({ path_with_namespace: pathWithNamespace }) => {
          openWebIDE(pathWithNamespace, README_FILE);
        })
        .catch(() => {
          this.hideModal();
          this.creatingReadme = false;
          createAlert({ message: this.$options.i18n.errorCreatingProject });
        });
    },
  },
  README_MODAL_ID,
};
</script>

<template>
  <div>
    <gl-button v-if="hasReadme" icon="doc-text" :href="groupReadmePath">{{
      $options.i18n.readme
    }}</gl-button>
    <gl-button
      v-else
      v-gl-modal="$options.README_MODAL_ID"
      variant="dashed"
      icon="file-addition"
      data-testid="group-settings-add-readme-button"
      >{{ $options.i18n.addReadme }}</gl-button
    >
    <gl-modal ref="modal" :modal-id="$options.README_MODAL_ID" :title="$options.i18n.addReadme">
      <div data-testid="group-settings-modal-readme-body">
        <gl-sprintf :message="modalBody">
          <template #path>
            <code>{{ pathToReadmeProject }}</code>
          </template>
        </gl-sprintf>
      </div>
      <template #modal-footer>
        <gl-button variant="default" @click="hideModal">{{ $options.i18n.cancel }}</gl-button>
        <gl-button v-if="creatingReadme" variant="default" loading disabled>{{
          $options.i18n.creatingReadme
        }}</gl-button>
        <gl-button
          v-else
          variant="confirm"
          data-testid="group-settings-modal-create-readme-button"
          @click="createReadme"
          >{{ modalSubmitButtonText }}</gl-button
        >
      </template>
    </gl-modal>
  </div>
</template>
