<script>
import {
  GlIcon,
  GlLink,
  GlForm,
  GlFormInput,
  GlFormGroup,
  GlFormTextarea,
  GlButton,
  GlSprintf,
  GlFormRadio,
  GlFormRadioGroup,
} from '@gitlab/ui';
import { kebabCase } from 'lodash';
import { buildApiUrl } from '~/api/api_utils';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import csrf from '~/lib/utils/csrf';
import { visitUrl } from '~/lib/utils/url_utility';
import { s__, __ } from '~/locale';
import validation from '~/vue_shared/directives/validation';
import HelpIcon from '~/vue_shared/components/help_icon/help_icon.vue';
import {
  VISIBILITY_LEVEL_PRIVATE_STRING,
  VISIBILITY_LEVEL_INTERNAL_STRING,
  VISIBILITY_LEVEL_PUBLIC_STRING,
  VISIBILITY_LEVELS_STRING_TO_INTEGER,
  VISIBILITY_LEVELS_INTEGER_TO_STRING,
} from '~/visibility_level/constants';
import { START_RULE, CONTAINS_RULE } from '~/projects/project_name_rules';
import ProjectNamespace from './project_namespace.vue';

const feedbackMap = {
  valueMissing: {
    isInvalid: (el) => el.validity?.valueMissing,
    message: __('Please fill out this field.'),
  },
  nameStartPattern: {
    isInvalid: (el) => el.validity?.patternMismatch && !START_RULE.reg.test(el.value),
    message: START_RULE.msg,
  },
  nameContainsPattern: {
    isInvalid: (el) => el.validity?.patternMismatch && !CONTAINS_RULE.reg.test(el.value),
    message: CONTAINS_RULE.msg,
  },
};

const initFormField = ({ value, required = true, skipValidation = false }) => ({
  value,
  required,
  state: skipValidation ? true : null,
  feedback: null,
});

export default {
  components: {
    GlForm,
    GlIcon,
    GlLink,
    GlButton,
    GlSprintf,
    GlFormInput,
    GlFormTextarea,
    GlFormGroup,
    GlFormRadio,
    GlFormRadioGroup,
    ProjectNamespace,
    HelpIcon,
  },
  directives: {
    validation: validation(feedbackMap),
  },
  inject: {
    newGroupPath: {
      default: '',
    },
    visibilityHelpPath: {
      default: '',
    },
    cancelPath: {
      default: '',
    },
    projectFullPath: {
      default: '',
    },
    projectId: {
      default: '',
    },
    projectName: {
      default: '',
    },
    projectPath: {
      default: '',
    },
    projectDescription: {
      default: '',
    },
    projectDefaultBranch: {
      default: '',
    },
    projectVisibility: {
      default: '',
    },
    restrictedVisibilityLevels: {
      default: [],
    },
    namespaceId: {
      default: '',
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
        branches: initFormField({ value: '', required: true, skipValidation: true }),
        visibility: initFormField({ value: null }),
      },
    };
    return {
      isSaving: false,
      form,
    };
  },
  computed: {
    projectNameDescription() {
      if (this.form.fields.name.state === false) {
        return null;
      }

      return s__(
        'ProjectsNew|Must start with a lowercase or uppercase letter, digit, emoji, or underscore. Can also contain dots, pluses, dashes, or spaces.',
      );
    },
    projectVisibilityLevel() {
      return VISIBILITY_LEVELS_STRING_TO_INTEGER[this.projectVisibility];
    },
    namespaceVisibilityLevel() {
      const visibility =
        this.form.fields.namespace.value?.visibility || VISIBILITY_LEVEL_PUBLIC_STRING;
      return VISIBILITY_LEVELS_STRING_TO_INTEGER[visibility];
    },
    visibilityLevelCap() {
      return Math.min(this.projectVisibilityLevel, this.namespaceVisibilityLevel);
    },
    restrictedVisibilityLevelsSet() {
      return new Set(this.restrictedVisibilityLevels);
    },
    allowedVisibilityLevels() {
      const allowedLevels = Object.entries(VISIBILITY_LEVELS_STRING_TO_INTEGER).reduce(
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
        return [VISIBILITY_LEVEL_PRIVATE_STRING];
      }

      return allowedLevels;
    },
    branchesOptions() {
      return [
        {
          text: s__('ForkProject|All branches'),
          value: '',
        },
        {
          text: s__(`ForkProject|Only the default branch %{defaultBranch}`),
          value: this.projectDefaultBranch,
        },
      ];
    },
    visibilityLevels() {
      return [
        {
          text: s__('ForkProject|Private'),
          value: VISIBILITY_LEVEL_PRIVATE_STRING,
          icon: 'lock',
          help: s__(
            'ForkProject|Project access must be granted explicitly to each user. If this project is part of a group, access will be granted to members of the group.',
          ),
          disabled: this.isVisibilityLevelDisabled(VISIBILITY_LEVEL_PRIVATE_STRING),
        },
        {
          text: s__('ForkProject|Internal'),
          value: VISIBILITY_LEVEL_INTERNAL_STRING,
          icon: 'shield',
          help: s__('ForkProject|The project can be accessed by any logged in user.'),
          disabled: this.isVisibilityLevelDisabled(VISIBILITY_LEVEL_INTERNAL_STRING),
        },
        {
          text: s__('ForkProject|Public'),
          value: VISIBILITY_LEVEL_PUBLIC_STRING,
          icon: 'earth',
          help: s__('ForkProject|The project can be accessed without any authentication.'),
          disabled: this.isVisibilityLevelDisabled(VISIBILITY_LEVEL_PUBLIC_STRING),
        },
      ];
    },
  },
  watch: {
    // eslint-disable-next-line func-names
    'form.fields.name.value': function (newVal) {
      this.form.fields.slug.value = kebabCase(newVal);
    },
  },
  created() {
    this.form.fields.visibility.value = this.getMaximumAllowedVisibilityLevel(
      VISIBILITY_LEVEL_PUBLIC_STRING,
    );
  },
  methods: {
    isVisibilityLevelDisabled(visibility) {
      return !this.allowedVisibilityLevels.includes(visibility);
    },
    setNamespace(namespace) {
      this.form.fields.namespace.value = namespace;
      this.form.fields.namespace.state = true;
      this.form.fields.visibility.value = this.getMaximumAllowedVisibilityLevel(
        this.form.fields.visibility.value,
      );
    },
    getMaximumAllowedVisibilityLevel(visibility) {
      const allowedVisibilities = this.allowedVisibilityLevels.map(
        (s) => VISIBILITY_LEVELS_STRING_TO_INTEGER[s],
      );
      const current = VISIBILITY_LEVELS_STRING_TO_INTEGER[visibility];
      const lower = allowedVisibilities.filter((l) => l <= current);
      if (lower.length) {
        return VISIBILITY_LEVELS_INTEGER_TO_STRING[Math.max(...lower)];
      }
      const higher = allowedVisibilities.filter((l) => l >= current);
      return VISIBILITY_LEVELS_INTEGER_TO_STRING[Math.min(...higher)];
    },
    async onSubmit() {
      this.form.showValidation = true;

      if (!this.form.fields.namespace.value) {
        this.form.fields.namespace.state = false;
      }

      if (!this.form.state) {
        return;
      }

      this.isSaving = true;
      this.form.showValidation = false;

      const { projectId } = this;
      const { name, slug, description, branches, visibility, namespace } = this.form.fields;

      const postParams = {
        id: projectId,
        name: name.value,
        namespace_id: namespace.value.id,
        path: slug.value,
        description: description.value,
        branches: branches.value,
        visibility: visibility.value,
      };

      const forkProjectPath = `/api/:version/projects/:id/fork`;
      const url = buildApiUrl(forkProjectPath).replace(':id', encodeURIComponent(this.projectId));

      try {
        const { data } = await axios.post(url, postParams);
        visitUrl(data.web_url);
      } catch (error) {
        this.isSaving = false;
        const message =
          error?.response?.data?.message?.join('. ') ||
          s__('ForkProject|An error occurred while forking the project. Please try again.');
        createAlert({
          message,
        });
      }
    },
  },
  csrf,
  projectNamePattern: `(${START_RULE.reg.source})|(${CONTAINS_RULE.reg.source})`,
};
</script>

<template>
  <gl-form novalidate method="POST" @submit.prevent="onSubmit">
    <input type="hidden" name="authenticity_token" :value="$options.csrf.token" />

    <gl-form-group
      :label="__('Project name')"
      :description="projectNameDescription"
      label-for="fork-name"
      :invalid-feedback="form.fields.name.feedback"
      data-testid="fork-name-form-group"
    >
      <gl-form-input
        id="fork-name"
        v-model="form.fields.name.value"
        v-validation:[form.showValidation]
        name="name"
        data-testid="fork-name-input"
        :state="form.fields.name.state"
        required
        :pattern="$options.projectNamePattern"
      />
    </gl-form-group>

    <div class="md:gl-flex">
      <div class="gl-basis-1/2">
        <gl-form-group
          :label="__('Project URL')"
          label-for="fork-url"
          class="md:gl-mr-3"
          :state="form.fields.namespace.state"
          :invalid-feedback="s__('ForkProject|Please select a namespace')"
        >
          <project-namespace @select="setNamespace" />
        </gl-form-group>
      </div>
      <div class="gl-basis-1/2">
        <gl-form-group
          :label="__('Project slug')"
          label-for="fork-slug"
          class="md:gl-ml-3"
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

    <p class="-gl-mt-3 gl-text-subtle">
      {{ s__('ForkProject|Want to organize several dependent projects under the same namespace?') }}
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
        no-resize
        :state="form.fields.description.state"
      />
    </gl-form-group>

    <gl-form-group>
      <label>
        {{ s__('ForkProject|Branches to include') }}
      </label>
      <gl-form-radio-group
        v-model="form.fields.branches.value"
        data-testid="fork-branches-radio-group"
        name="branches"
        :aria-label="__('branches')"
        required
      >
        <gl-form-radio
          v-for="{ text, value } in branchesOptions"
          :key="value"
          :value="value"
          :data-testid="`radio-${value}`"
        >
          <div>
            <gl-sprintf :message="text">
              <template #defaultBranch>
                <code class="gl-ml-2">{{ projectDefaultBranch }}</code>
              </template>
            </gl-sprintf>
          </div>
        </gl-form-radio>
      </gl-form-radio-group>
    </gl-form-group>

    <gl-form-group
      v-validation:[form.showValidation]
      :invalid-feedback="s__('ForkProject|Please select a visibility level')"
      :state="form.fields.visibility.state"
    >
      <label>
        {{ s__('ForkProject|Visibility level') }}
        <gl-link :href="visibilityHelpPath" target="_blank">
          <help-icon />
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
            <gl-icon
              data-testid="fork-privacy-button"
              :name="icon"
              :data-qa-privacy-level="`${value}`"
            />
            <span>{{ text }}</span>
          </div>
          <template #help>{{ help }}</template>
        </gl-form-radio>
      </gl-form-radio-group>
    </gl-form-group>

    <div class="gl-mt-8 gl-flex gl-justify-between">
      <gl-button
        type="submit"
        category="primary"
        variant="confirm"
        class="js-no-auto-disable"
        data-testid="fork-project-button"
        :loading="isSaving"
      >
        {{ s__('ForkProject|Fork project') }}
      </gl-button>
      <gl-button
        type="reset"
        class="gl-mr-3"
        data-testid="cancel-button"
        :disabled="isSaving"
        :href="cancelPath"
      >
        {{ s__('ForkProject|Cancel') }}
      </gl-button>
    </div>
  </gl-form>
</template>
