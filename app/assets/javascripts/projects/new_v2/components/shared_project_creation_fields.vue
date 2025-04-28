<script>
import { GlFormGroup, GlFormInput, GlFormSelect, GlSprintf, GlLink } from '@gitlab/ui';
import { kebabCase } from 'lodash';
import { helpPagePath } from '~/helpers/help_page_helper';
import validation, { initForm } from '~/vue_shared/directives/validation';
import { K8S_OPTION, DEPLOYMENT_TARGET_SELECTIONS } from '../form_constants';
import NewProjectDestinationSelect from './project_destination_select.vue';

export default {
  components: {
    GlFormGroup,
    GlFormInput,
    GlFormSelect,
    GlSprintf,
    GlLink,
    NewProjectDestinationSelect,
  },
  directives: {
    validation: validation(),
  },
  props: {
    namespace: {
      type: Object,
      required: true,
    },
  },
  data() {
    const form = initForm({
      fields: {
        'project[name]': { value: null },
        'project[path]': { value: null },
      },
    });
    return {
      form,
      selectedNamespace: this.namespace,
      selectedTarget: null,
    };
  },
  computed: {
    isK8sOptionSelected() {
      return this.selectedTarget === K8S_OPTION.value;
    },
  },
  methods: {
    updateSlug() {
      this.form.fields['project[path]'].value = kebabCase(this.form.fields['project[name]'].value);
    },
    onSelectNamespace(newNamespace) {
      this.$emit('onSelectNamespace', newNamespace);
    },
  },
  helpPageK8s: helpPagePath('user/clusters/agent/_index'),
  K8S_OPTION,
  DEPLOYMENT_TARGET_SELECTIONS,
};
</script>

<template>
  <div>
    <gl-form-group
      :label="s__('ProjectsNew|Project name')"
      label-for="project[name]"
      :description="
        s__(
          'ProjectsNew|Must start with a lowercase or uppercase letter, digit, emoji, or underscore. Can also contain dots, pluses, dashes, or spaces.',
        )
      "
      :invalid-feedback="form.fields['project[name]'].feedback"
      data-testid="project-name-group"
    >
      <gl-form-input
        id="project[name]"
        v-model="form.fields['project[name]'].value"
        v-validation:[form.showValidation]
        :validation-message="s__('ProjectsNew|Please enter project name.')"
        :state="form.fields['project[name]'].state"
        name="project[name]"
        required
        :placeholder="s__('ProjectsNew|My awesome project')"
        data-testid="project-name-input"
        @input="updateSlug"
      />
    </gl-form-group>

    <div class="gl-flex gl-flex-col gl-gap-4 sm:gl-flex-row">
      <gl-form-group
        class="sm:gl-w-1/2"
        :invalid-feedback="
          s__('ProjectsNew|Pick a group or namespace where you want to create this project.')
        "
        :state="selectedNamespace.id !== null"
        data-testid="project-namespace-group"
      >
        <template #label>
          <label id="namespace-selector" for="namespace" class="gl-mb-0">
            {{ s__('ProjectsNew|Choose a group or namespace') }}
          </label>
        </template>
        <new-project-destination-select
          toggle-aria-labelled-by="namespace-selector"
          toggle-id="namespace"
          :namespace-id="selectedNamespace.id"
          :namespace-full-path="selectedNamespace.fullPath"
          @onSelectNamespace="onSelectNamespace"
        />
      </gl-form-group>

      <div class="gl-mt-2 gl-hidden gl-pt-6 sm:gl-block">/</div>

      <gl-form-group
        :label="s__('ProjectsNew|Project slug')"
        label-for="project[path]"
        class="sm:gl-w-1/2"
        :invalid-feedback="form.fields['project[path]'].feedback"
        data-testid="project-slug-group"
      >
        <gl-form-input
          id="project[path]"
          v-model="form.fields['project[path]'].value"
          v-validation:[form.showValidation]
          :validation-message="s__('ProjectsNew|Please enter project slug.')"
          :state="form.fields['project[path]'].state"
          name="project[path]"
          required
          :placeholder="s__('ProjectsNew|my-awesome-project')"
          data-testid="project-slug-input"
        />
      </gl-form-group>
    </div>

    <gl-form-group
      :label="s__('Deployment Target|Project deployment target (optional)')"
      label-for="deployment-target-select"
      data-testid="deployment-target-form-group"
    >
      <gl-form-select
        id="deployment-target-select"
        v-model="selectedTarget"
        :options="$options.DEPLOYMENT_TARGET_SELECTIONS"
        class="gl-w-full"
        data-testid="deployment-target-select"
      >
        <template #first>
          <option :value="null" disabled>
            {{ s__('Deployment Target|Select the deployment target') }}
          </option>
        </template>
      </gl-form-select>

      <template v-if="isK8sOptionSelected" #description>
        <gl-sprintf
          :message="
            s__(
              'Deployment Target|%{linkStart}How to provision or deploy to Kubernetes clusters from GitLab?%{linkEnd}',
            )
          "
        >
          <template #link="{ content }">
            <gl-link
              :href="$options.helpPageK8s"
              data-track-action="visit_docs"
              data-track-label="new_project_deployment_target"
              >{{ content }}</gl-link
            >
          </template>
        </gl-sprintf>
      </template>
    </gl-form-group>

    <!-- Visibility Level should be added in: https://gitlab.com/gitlab-org/gitlab/-/issues/514700 -->
  </div>
</template>
