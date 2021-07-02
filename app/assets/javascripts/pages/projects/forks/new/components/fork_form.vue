<script>
import {
  GlIcon,
  GlLink,
  GlForm,
  GlFormInputGroup,
  GlInputGroupText,
  GlFormInput,
  GlFormGroup,
  GlFormTextarea,
  GlButton,
  GlFormRadio,
  GlFormRadioGroup,
  GlFormSelect,
} from '@gitlab/ui';
import { kebabCase } from 'lodash';
import { buildApiUrl } from '~/api/api_utils';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import csrf from '~/lib/utils/csrf';
import { redirectTo } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';
import validation from '~/vue_shared/directives/validation';

const PRIVATE_VISIBILITY = 'private';
const INTERNAL_VISIBILITY = 'internal';
const PUBLIC_VISIBILITY = 'public';

const VISIBILITY_LEVEL = {
  [PRIVATE_VISIBILITY]: 0,
  [INTERNAL_VISIBILITY]: 10,
  [PUBLIC_VISIBILITY]: 20,
};

const initFormField = ({ value, required = true, skipValidation = false }) => ({
  value,
  required,
  state: skipValidation ? true : null,
  feedback: null,
});

function sortNamespaces(namespaces) {
  if (!namespaces || !namespaces?.length) {
    return namespaces;
  }

  return namespaces.sort((a, b) => a.name.localeCompare(b.name));
}

export default {
  components: {
    GlForm,
    GlIcon,
    GlLink,
    GlButton,
    GlFormInputGroup,
    GlInputGroupText,
    GlFormInput,
    GlFormTextarea,
    GlFormGroup,
    GlFormRadio,
    GlFormRadioGroup,
    GlFormSelect,
  },
  directives: {
    validation: validation(),
  },
  inject: {
    newGroupPath: {
      default: '',
    },
    visibilityHelpPath: {
      default: '',
    },
  },
  props: {
    endpoint: {
      type: String,
      required: true,
    },
    projectFullPath: {
      type: String,
      required: true,
    },
    projectId: {
      type: String,
      required: true,
    },
    projectName: {
      type: String,
      required: true,
    },
    projectPath: {
      type: String,
      required: true,
    },
    projectDescription: {
      type: String,
      required: false,
      default: '',
    },
    projectVisibility: {
      type: String,
      required: true,
    },
    restrictedVisibilityLevels: {
      type: Array,
      required: true,
    },
  },
  data() {
    const form = {
      state: false,
      showValidation: false,
      fields: {
        namespace: initFormField({
          value: null,
        }),
        name: initFormField({ value: this.projectName }),
        slug: initFormField({ value: this.projectPath }),
        description: initFormField({
          value: this.projectDescription,
          required: false,
          skipValidation: true,
        }),
        visibility: initFormField({ value: this.getInitialVisibilityValue() }),
      },
    };
    return {
      isSaving: false,
      namespaces: [],
      form,
    };
  },
  computed: {
    projectUrl() {
      return `${gon.gitlab_url}/`;
    },
    projectVisibilityLevel() {
      return VISIBILITY_LEVEL[this.projectVisibility];
    },
    namespaceVisibilityLevel() {
      const visibility = this.form.fields.namespace.value?.visibility || PUBLIC_VISIBILITY;
      return VISIBILITY_LEVEL[visibility];
    },
    visibilityLevelCap() {
      return Math.min(this.projectVisibilityLevel, this.namespaceVisibilityLevel);
    },
    restrictedVisibilityLevelsSet() {
      return new Set(this.restrictedVisibilityLevels);
    },
    allowedVisibilityLevels() {
      const allowedLevels = Object.entries(VISIBILITY_LEVEL).reduce(
        (levels, [levelName, levelValue]) => {
          if (
            !this.restrictedVisibilityLevelsSet.has(levelValue) &&
            levelValue <= this.visibilityLevelCap
          ) {
            levels.push(levelName);
          }
          return levels;
        },
        [],
      );

      if (!allowedLevels.length) {
        return [PRIVATE_VISIBILITY];
      }

      return allowedLevels;
    },
    visibilityLevels() {
      return [
        {
          text: s__('ForkProject|Private'),
          value: PRIVATE_VISIBILITY,
          icon: 'lock',
          help: s__(
            'ForkProject|Project access must be granted explicitly to each user. If this project is part of a group, access will be granted to members of the group.',
          ),
          disabled: this.isVisibilityLevelDisabled(PRIVATE_VISIBILITY),
        },
        {
          text: s__('ForkProject|Internal'),
          value: INTERNAL_VISIBILITY,
          icon: 'shield',
          help: s__('ForkProject|The project can be accessed by any logged in user.'),
          disabled: this.isVisibilityLevelDisabled(INTERNAL_VISIBILITY),
        },
        {
          text: s__('ForkProject|Public'),
          value: PUBLIC_VISIBILITY,
          icon: 'earth',
          help: s__('ForkProject|The project can be accessed without any authentication.'),
          disabled: this.isVisibilityLevelDisabled(PUBLIC_VISIBILITY),
        },
      ];
    },
  },
  watch: {
    // eslint-disable-next-line func-names
    'form.fields.namespace.value': function () {
      this.form.fields.visibility.value =
        this.restrictedVisibilityLevels.length !== 0 ? null : PRIVATE_VISIBILITY;
    },
    // eslint-disable-next-line func-names
    'form.fields.name.value': function (newVal) {
      this.form.fields.slug.value = kebabCase(newVal);
    },
  },
  mounted() {
    this.fetchNamespaces();
  },
  methods: {
    async fetchNamespaces() {
      const { data } = await axios.get(this.endpoint);
      this.namespaces = sortNamespaces(data.namespaces);
    },
    isVisibilityLevelDisabled(visibility) {
      return !this.allowedVisibilityLevels.includes(visibility);
    },
    getInitialVisibilityValue() {
      return this.restrictedVisibilityLevels.length !== 0 ? null : this.projectVisibility;
    },
    async onSubmit() {
      this.form.showValidation = true;

      if (!this.form.state) {
        return;
      }

      this.isSaving = true;
      this.form.showValidation = false;

      const { projectId } = this;
      const { name, slug, description, visibility, namespace } = this.form.fields;

      const postParams = {
        id: projectId,
        name: name.value,
        namespace_id: namespace.value.id,
        path: slug.value,
        description: description.value,
        visibility: visibility.value,
      };

      const forkProjectPath = `/api/:version/projects/:id/fork`;
      const url = buildApiUrl(forkProjectPath).replace(':id', encodeURIComponent(this.projectId));

      try {
        const { data } = await axios.post(url, postParams);
        redirectTo(data.web_url);
        return;
      } catch (error) {
        createFlash({
          message: s__(
            'ForkProject|An error occurred while forking the project. Please try again.',
          ),
        });
      }
    },
  },
  csrf,
};
</script>

<template>
  <gl-form novalidate method="POST" @submit.prevent="onSubmit">
    <input type="hidden" name="authenticity_token" :value="$options.csrf.token" />

    <gl-form-group
      :label="__('Project name')"
      label-for="fork-name"
      :invalid-feedback="form.fields.name.feedback"
    >
      <gl-form-input
        id="fork-name"
        v-model="form.fields.name.value"
        v-validation:[form.showValidation]
        name="name"
        data-testid="fork-name-input"
        :state="form.fields.name.state"
        required
      />
    </gl-form-group>

    <div class="gl-md-display-flex">
      <div class="gl-flex-basis-half">
        <gl-form-group
          :label="__('Project URL')"
          label-for="fork-url"
          class="gl-md-mr-3"
          :state="form.fields.namespace.state"
          :invalid-feedback="s__('ForkProject|Please select a namespace')"
        >
          <gl-form-input-group>
            <template #prepend>
              <gl-input-group-text>
                {{ projectUrl }}
              </gl-input-group-text>
            </template>
            <gl-form-select
              id="fork-url"
              v-model="form.fields.namespace.value"
              v-validation:[form.showValidation]
              name="namespace"
              data-testid="fork-url-input"
              data-qa-selector="fork_namespace_dropdown"
              :state="form.fields.namespace.state"
              required
            >
              <template #first>
                <option :value="null" disabled>{{ s__('ForkProject|Select a namespace') }}</option>
              </template>
              <option v-for="namespace in namespaces" :key="namespace.id" :value="namespace">
                {{ namespace.name }}
              </option>
            </gl-form-select>
          </gl-form-input-group>
        </gl-form-group>
      </div>
      <div class="gl-flex-basis-half">
        <gl-form-group
          :label="__('Project slug')"
          label-for="fork-slug"
          class="gl-md-ml-3"
          :invalid-feedback="form.fields.slug.feedback"
        >
          <gl-form-input
            id="fork-slug"
            v-model="form.fields.slug.value"
            v-validation:[form.showValidation]
            data-testid="fork-slug-input"
            name="slug"
            :state="form.fields.slug.state"
            required
          />
        </gl-form-group>
      </div>
    </div>

    <p class="gl-mt-n5 gl-text-gray-500">
      {{ s__('ForkProject|Want to house several dependent projects under the same namespace?') }}
      <gl-link :href="newGroupPath" target="_blank">
        {{ s__('ForkProject|Create a group') }}
      </gl-link>
    </p>

    <gl-form-group :label="__('Project description (optional)')" label-for="fork-description">
      <gl-form-textarea
        id="fork-description"
        v-model="form.fields.description.value"
        data-testid="fork-description-textarea"
        name="description"
        :state="form.fields.description.state"
      />
    </gl-form-group>

    <gl-form-group
      v-validation:[form.showValidation]
      :invalid-feedback="s__('ForkProject|Please select a visibility level')"
      :state="form.fields.visibility.state"
    >
      <label>
        {{ s__('ForkProject|Visibility level') }}
        <gl-link :href="visibilityHelpPath" target="_blank">
          <gl-icon name="question-o" />
        </gl-link>
      </label>
      <gl-form-radio-group
        v-model="form.fields.visibility.value"
        data-testid="fork-visibility-radio-group"
        name="visibility"
        :aria-label="__('visibility')"
        required
      >
        <gl-form-radio
          v-for="{ text, value, icon, help, disabled } in visibilityLevels"
          :key="value"
          :value="value"
          :disabled="disabled"
          :data-testid="`radio-${value}`"
        >
          <div>
            <gl-icon :name="icon" />
            <span>{{ text }}</span>
          </div>
          <template #help>{{ help }}</template>
        </gl-form-radio>
      </gl-form-radio-group>
    </gl-form-group>

    <div class="gl-display-flex gl-justify-content-space-between gl-mt-8">
      <gl-button
        type="submit"
        category="primary"
        variant="confirm"
        class="js-no-auto-disable"
        data-testid="submit-button"
        data-qa-selector="fork_project_button"
        :loading="isSaving"
      >
        {{ s__('ForkProject|Fork project') }}
      </gl-button>
      <gl-button
        type="reset"
        class="gl-mr-3"
        data-testid="cancel-button"
        :disabled="isSaving"
        :href="projectFullPath"
      >
        {{ s__('ForkProject|Cancel') }}
      </gl-button>
    </div>
  </gl-form>
</template>
