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

const PRIVATE_VISIBILITY = 'private';
const INTERNAL_VISIBILITY = 'internal';
const PUBLIC_VISIBILITY = 'public';

const ALLOWED_VISIBILITY = {
  private: [PRIVATE_VISIBILITY],
  internal: [INTERNAL_VISIBILITY, PRIVATE_VISIBILITY],
  public: [INTERNAL_VISIBILITY, PRIVATE_VISIBILITY, PUBLIC_VISIBILITY],
};

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
      required: true,
    },
    projectVisibility: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isSaving: false,
      namespaces: [],
      selectedNamespace: {},
      fork: {
        name: this.projectName,
        slug: this.projectPath,
        description: this.projectDescription,
        visibility: this.projectVisibility,
      },
    };
  },
  computed: {
    projectUrl() {
      return `${gon.gitlab_url}/`;
    },
    projectAllowedVisibility() {
      return ALLOWED_VISIBILITY[this.projectVisibility];
    },
    namespaceAllowedVisibility() {
      return (
        ALLOWED_VISIBILITY[this.selectedNamespace.visibility] ||
        ALLOWED_VISIBILITY[PUBLIC_VISIBILITY]
      );
    },
    visibilityLevels() {
      return [
        {
          text: s__('ForkProject|Private'),
          value: PRIVATE_VISIBILITY,
          icon: 'lock',
          help: s__('ForkProject|The project can be accessed without any authentication.'),
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
          help: s__(
            'ForkProject|Project access must be granted explicitly to each user. If this project is part of a group, access will be granted to members of the group.',
          ),
          disabled: this.isVisibilityLevelDisabled(PUBLIC_VISIBILITY),
        },
      ];
    },
  },
  watch: {
    selectedNamespace(newVal) {
      const { visibility } = newVal;

      if (this.projectAllowedVisibility.includes(visibility)) {
        this.fork.visibility = visibility;
      }
    },
    // eslint-disable-next-line func-names
    'fork.name': function (newVal) {
      this.fork.slug = kebabCase(newVal);
    },
  },
  mounted() {
    this.fetchNamespaces();
  },
  methods: {
    async fetchNamespaces() {
      const { data } = await axios.get(this.endpoint);
      this.namespaces = data.namespaces;
    },
    isVisibilityLevelDisabled(visibilityLevel) {
      return !(
        this.projectAllowedVisibility.includes(visibilityLevel) &&
        this.namespaceAllowedVisibility.includes(visibilityLevel)
      );
    },
    async onSubmit() {
      this.isSaving = true;

      const { projectId } = this;
      const { name, slug, description, visibility } = this.fork;
      const { id: namespaceId } = this.selectedNamespace;

      const postParams = {
        id: projectId,
        name,
        namespace_id: namespaceId,
        path: slug,
        description,
        visibility,
      };

      const forkProjectPath = `/api/:version/projects/:id/fork`;
      const url = buildApiUrl(forkProjectPath).replace(':id', encodeURIComponent(this.projectId));

      try {
        const { data } = await axios.post(url, postParams);
        redirectTo(data.web_url);
        return;
      } catch (error) {
        createFlash({ message: error });
      }
    },
  },
  csrf,
};
</script>

<template>
  <gl-form method="POST" @submit.prevent="onSubmit">
    <input type="hidden" name="authenticity_token" :value="$options.csrf.token" />

    <gl-form-group label="Project name" label-for="fork-name">
      <gl-form-input id="fork-name" v-model="fork.name" data-testid="fork-name-input" required />
    </gl-form-group>

    <div class="gl-md-display-flex">
      <div class="gl-flex-basis-half">
        <gl-form-group label="Project URL" label-for="fork-url" class="gl-md-mr-3">
          <gl-form-input-group>
            <template #prepend>
              <gl-input-group-text>
                {{ projectUrl }}
              </gl-input-group-text>
            </template>
            <gl-form-select
              id="fork-url"
              v-model="selectedNamespace"
              data-testid="fork-url-input"
              data-qa-selector="fork_namespace_dropdown"
              required
            >
              <template slot="first">
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
        <gl-form-group label="Project slug" label-for="fork-slug" class="gl-md-ml-3">
          <gl-form-input
            id="fork-slug"
            v-model="fork.slug"
            data-testid="fork-slug-input"
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

    <gl-form-group label="Project description (optional)" label-for="fork-description">
      <gl-form-textarea
        id="fork-description"
        v-model="fork.description"
        data-testid="fork-description-textarea"
      />
    </gl-form-group>

    <gl-form-group>
      <label>
        {{ s__('ForkProject|Visibility level') }}
        <gl-link :href="visibilityHelpPath" target="_blank">
          <gl-icon name="question-o" />
        </gl-link>
      </label>
      <gl-form-radio-group
        v-model="fork.visibility"
        data-testid="fork-visibility-radio-group"
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
