<script>
import {
  GlAlert,
  GlButton,
  GlButtonGroup,
  GlCollapsibleListbox,
  GlFormGroup,
  GlFormInput,
  GlFormInputGroup,
  GlInputGroupText,
  GlLink,
} from '@gitlab/ui';
import { debounce } from 'lodash-es';

import { __, s__ } from '~/locale';
import { getGroupPathAvailability } from '~/rest_api';
import { createAlert } from '~/alert';
import { slugify } from '~/lib/utils/text_utility';
import axios from '~/lib/utils/axios_utils';
import { helpPagePath } from '~/helpers/help_page_helper';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { MINIMUM_SEARCH_LENGTH } from '~/graphql_shared/constants';
import { DEBOUNCE_DELAY } from '~/vue_shared/components/filtered_search_bar/constants';

import { checkGroupNameRules } from '../group_name_rules';
import { validateGroupPath } from '../group_path_rules';
import searchGroupsWhereUserCanCreateSubgroups from '../queries/search_groups_where_user_can_create_subgroups.query.graphql';

const DEBOUNCE_DURATION = 1000;

export default {
  name: 'GroupNameAndPath',
  i18n: {
    inputs: {
      name: {
        placeholder: __('My group'),
        description: s__('Groups|Start with a letter, digit, emoji, or underscore.'),
        warningForUsingDotInName: s__(
          'Groups|Your group name must not contain a period if you intend to use SCIM integration, as it can lead to errors.',
        ),
      },
      path: {
        placeholder: __('my-awesome-group'),
        invalidFeedbackPathUnavailable: s__(
          'Groups|Group path is unavailable. Path has been replaced with a suggested available path.',
        ),
        validFeedback: s__('Groups|Group path is available.'),
      },
    },
    apiLoadingMessage: s__('Groups|Checking group URL availability…'),
    apiErrorMessage: __(
      'An error occurred while checking group path. Please refresh and try again.',
    ),
    changingUrlWarningMessage: s__('Groups|Changing group URL can have unintended side effects.'),
    learnMore: __('Learn more'),
  },
  inputSize: { md: 'lg' },
  nameMaxLength: 255,
  changingGroupPathHelpPagePath: helpPagePath('user/group/manage', {
    anchor: 'change-a-groups-path',
  }),
  mattermostDataBindName: 'create_chat_team',
  components: {
    GlFormGroup,
    GlFormInput,
    GlFormInputGroup,
    GlInputGroupText,
    GlLink,
    GlAlert,
    GlButton,
    GlButtonGroup,
    GlCollapsibleListbox,
  },
  inject: ['fields', 'basePath', 'newSubgroup', 'mattermostEnabled'],
  data() {
    return {
      name: this.fields.name.value,
      path: this.fields.path.value,
      hasPathBeenManuallySet: false,
      apiSuggestedPath: '',
      apiLoading: false,
      nameFeedbackState: null,
      pathFeedbackState: null,
      pathInvalidFeedback: null,
      activeApiRequestAbortController: null,
      search: '',
      isLoading: false,
      isSearchLoading: false,
      currentUserGroups: null,
      selectedGroup: {
        id: this.fields.parentId.value,
        fullPath: this.fields.parentFullPath.value,
      },
    };
  },
  computed: {
    groupItems() {
      return this.currentUserGroups && this.currentUserGroups.length
        ? this.currentUserGroups.map((group) => ({
            value: group.id,
            text: group.fullPath,
          }))
        : [];
    },
    inputLabels() {
      return {
        name: this.newSubgroup ? s__('Groups|Subgroup name') : s__('Groups|Group name'),
        path: this.newSubgroup ? s__('Groups|Subgroup slug') : s__('Groups|Group URL'),
        subgroupPath: s__('Groups|Subgroup URL'),
        groupId: s__('Groups|Group ID'),
      };
    },
    pathInputSize() {
      return this.newSubgroup ? {} : this.$options.inputSize;
    },
    computedPath() {
      return this.apiSuggestedPath || this.path;
    },
    pathDescription() {
      return this.apiLoading ? this.$options.i18n.apiLoadingMessage : '';
    },
    nameDescription() {
      return this.nameFeedbackState === false ? '' : this.$options.i18n.inputs.name.description;
    },
    isEditingGroup() {
      return this.fields.groupId.value !== '';
    },
    isInitialLoading() {
      return this.isLoading && !this.isSearchLoading;
    },
    shouldShowEmptyState() {
      return this.currentUserGroups && this.currentUserGroups.length === 0;
    },
    pathInputClass() {
      if (this.hasPathBeenManuallySet || !this.computedPath?.length) return '';

      return '!gl-bg-feedback-info';
    },
    pathValidationError() {
      return validateGroupPath(this.path);
    },
    nameValidationError() {
      return checkGroupNameRules(this.name);
    },
  },
  watch: {
    name: [
      function validateName() {
        if (this.nameValidationError) {
          this.nameFeedbackState = false;
          // Set HTML5 validation message so form cannot be submitted until fixed
          this.$refs.nameInput.$el.setCustomValidity(this.nameValidationError);
          return;
        }

        this.nameFeedbackState = null;
        // Clear HTML5 validation message so form can be submitted
        this.$refs.nameInput.$el.setCustomValidity('');
      },
      function updatePath(newName) {
        if (this.isEditingGroup || this.hasPathBeenManuallySet) return;

        this.pathFeedbackState = null;
        this.apiSuggestedPath = '';
        this.path = slugify(newName);

        if (!this.path) return;

        if (this.pathValidationError) {
          this.abortActiveRequest();
          this.pathInvalidFeedback = this.pathValidationError;
          this.pathFeedbackState = false;
          // Set HTML5 validation message so form cannot be submitted until fixed
          this.$refs.pathInput.$el.setCustomValidity(this.pathValidationError);
        } else {
          this.pathInvalidFeedback = null;
          // Clear HTML5 validation message so form can be submitted
          this.$refs.pathInput.$el.setCustomValidity('');
        }
      },
      debounce(async function updatePathWithSuggestions() {
        if (this.isEditingGroup || this.hasPathBeenManuallySet) return;
        if (this.pathValidationError) return;

        try {
          const { suggests } = await this.checkPathAvailability();

          const [suggestedPath] = suggests;

          this.apiSuggestedPath = suggestedPath;
        } catch (error) {
          // Do nothing, error handled in `checkPathAvailability`
        }
      }, DEBOUNCE_DURATION),
    ],
  },
  methods: {
    async fetchGroups(searchTerm = '') {
      try {
        const { data } = await this.$apollo.query({
          query: searchGroupsWhereUserCanCreateSubgroups,
          variables: {
            search: searchTerm,
          },
        });
        this.currentUserGroups = data.currentUser?.groups?.nodes || [];
      } finally {
        this.isLoading = false;
        this.isSearchLoading = false;
      }
    },
    debouncedFetchGroups: debounce(function fetchGroups(searchTerm) {
      this.fetchGroups(searchTerm);
    }, DEBOUNCE_DELAY),
    abortActiveRequest() {
      if (this.activeApiRequestAbortController === null) return;

      this.activeApiRequestAbortController.abort();
      this.activeApiRequestAbortController = null;
      this.apiLoading = false;
    },
    async checkPathAvailability() {
      if (!this.path) return Promise.reject();

      this.abortActiveRequest();
      this.apiLoading = true;
      this.activeApiRequestAbortController = new AbortController();

      try {
        const {
          data: { exists, suggests },
        } = await getGroupPathAvailability(
          this.path,
          this.selectedGroup.id || this.fields.parentId.value,
          { signal: this.activeApiRequestAbortController.signal },
        );

        this.apiLoading = false;

        if (exists) {
          if (suggests.length) {
            return Promise.resolve({ exists, suggests });
          }

          createAlert({
            message: this.$options.i18n.apiErrorMessage,
          });

          return Promise.reject();
        }

        return Promise.resolve({ exists, suggests });
      } catch (error) {
        if (!axios.isCancel(error)) {
          this.apiLoading = false;

          createAlert({
            message: this.$options.i18n.apiErrorMessage,
          });
        }

        return Promise.reject();
      }
    },
    handlePathInput(value) {
      this.pathFeedbackState = null;
      this.apiSuggestedPath = '';
      this.hasPathBeenManuallySet = true;
      this.path = value;

      if (this.pathValidationError) {
        this.abortActiveRequest();
        this.pathInvalidFeedback = this.pathValidationError;
        this.pathFeedbackState = false;
        // Set HTML5 validation message so form cannot be submitted until fixed
        this.$refs.pathInput.$el.setCustomValidity(this.pathValidationError);
        return;
      }

      this.pathInvalidFeedback = null;
      // Clear HTML5 validation message so form can be submitted
      this.$refs.pathInput.$el.setCustomValidity('');
      this.debouncedValidatePath();
    },
    debouncedValidatePath: debounce(async function validatePath() {
      if (this.isEditingGroup && this.path === this.fields.path.value) return;

      if (this.pathValidationError) return;

      try {
        const {
          exists,
          suggests: [suggestedPath],
        } = await this.checkPathAvailability();

        if (exists) {
          this.apiSuggestedPath = suggestedPath;
          this.pathInvalidFeedback = this.$options.i18n.inputs.path.invalidFeedbackPathUnavailable;
          this.pathFeedbackState = false;
        } else {
          this.pathFeedbackState = true;
        }
      } catch (error) {
        // Do nothing, error handled in `checkPathAvailability`
      }
    }, DEBOUNCE_DURATION),
    handleInvalidName(event) {
      event.preventDefault();

      this.nameFeedbackState = false;
    },
    handleInvalidPath(event) {
      event.preventDefault();

      this.pathFeedbackState = false;
      this.pathInvalidFeedback = this.pathValidationError;
    },
    handleDropdownShown() {
      if (!this.currentUserGroups) {
        this.isLoading = true;
        this.debouncedFetchGroups();
      }
    },
    handleSearchInput(searchValue) {
      this.search = searchValue.trim();

      // Don't search if not enough characters
      if (this.search.length > 0 && this.search.length < MINIMUM_SEARCH_LENGTH) {
        return;
      }

      this.isSearchLoading = true;
      this.debouncedFetchGroups(this.search);
    },
    handleDropdownItemClick(selectedItemValue) {
      const selectedGroup = this.currentUserGroups.find((group) => group.id === selectedItemValue);
      if (selectedGroup) {
        this.selectedGroup = {
          id: getIdFromGraphQLId(selectedGroup.id),
          fullPath: selectedGroup.fullPath,
        };

        this.debouncedValidatePath();
      }
    },
  },
};
</script>

<template>
  <div>
    <input
      :id="fields.parentId.id"
      type="hidden"
      :name="fields.parentId.name"
      :value="selectedGroup.id"
    />
    <gl-form-group
      :label="inputLabels.name"
      :description="nameDescription"
      :label-for="fields.name.id"
      :invalid-feedback="nameValidationError"
      :state="nameFeedbackState"
    >
      <gl-form-input
        :id="fields.name.id"
        ref="nameInput"
        v-model="name"
        class="gl-field-error-ignore !gl-h-auto"
        required
        :name="fields.name.name"
        :placeholder="$options.i18n.inputs.name.placeholder"
        :maxlength="$options.nameMaxLength"
        data-testid="group-name-field"
        :width="$options.inputSize"
        :state="nameFeedbackState"
        @invalid="handleInvalidName"
      />
    </gl-form-group>
    <gl-alert
      class="gl-mb-5"
      :dismissible="false"
      variant="warning"
      data-testid="dot-in-path-alert"
    >
      {{ $options.i18n.inputs.name.warningForUsingDotInName }}
    </gl-alert>

    <div :class="newSubgroup && 'row gl-mb-3'">
      <gl-form-group
        v-if="newSubgroup"
        class="gl-col-sm-6 gl-pr-0"
        :label="inputLabels.subgroupPath"
      >
        <div class="input-group gl-flex-nowrap">
          <gl-button-group class="gl-w-full">
            <gl-button class="js-group-namespace-button !gl-grow-0 gl-truncate" label>
              {{ basePath }}
            </gl-button>

            <gl-collapsible-listbox
              ref="search"
              data-testid="select_group_dropdown_item"
              :items="groupItems"
              :loading="isInitialLoading"
              :searching="isSearchLoading"
              :toggle-text="selectedGroup.fullPath"
              searchable
              :search-placeholder="__('Search groups')"
              :no-results-text="shouldShowEmptyState ? __('No matches found') : ''"
              class="gl-grow"
              block
              @shown="handleDropdownShown"
              @select="handleDropdownItemClick"
              @search="handleSearchInput"
            />
          </gl-button-group>

          <div class="gl-self-center gl-pl-5">
            <span class="gl-hidden @md/panel:gl-inline">/</span>
          </div>
        </div>
      </gl-form-group>

      <gl-form-group
        :class="newSubgroup && 'gl-col-sm-6'"
        :label="inputLabels.path"
        :label-for="fields.path.id"
        :description="pathDescription"
        :state="pathFeedbackState"
        :valid-feedback="$options.i18n.inputs.path.validFeedback"
        :invalid-feedback="pathInvalidFeedback"
      >
        <gl-form-input-group>
          <template v-if="!newSubgroup" #prepend>
            <gl-input-group-text class="group-root-path">
              {{ basePath.concat(fields.parentFullPath.value) }}
            </gl-input-group-text>
          </template>
          <gl-form-input
            :id="fields.path.id"
            ref="pathInput"
            class="gl-field-error-ignore !gl-h-auto"
            :class="pathInputClass"
            :name="fields.path.name"
            :value="computedPath"
            :placeholder="$options.i18n.inputs.path.placeholder"
            :maxlength="fields.path.maxLength"
            :state="pathFeedbackState"
            :width="pathInputSize"
            required
            data-testid="group-path-field"
            :data-bind-in="mattermostEnabled ? $options.mattermostDataBindName : null"
            @input="handlePathInput"
            @invalid="handleInvalidPath"
          />
        </gl-form-input-group>
      </gl-form-group>
    </div>

    <template v-if="isEditingGroup">
      <gl-alert
        class="gl-mb-5"
        :dismissible="false"
        variant="warning"
        data-testid="changing-url-alert"
      >
        {{ $options.i18n.changingUrlWarningMessage }}
        <gl-link :href="$options.changingGroupPathHelpPagePath"
          >{{ $options.i18n.learnMore }}
        </gl-link>
      </gl-alert>
      <gl-form-group :label="inputLabels.groupId" :label-for="fields.groupId.id">
        <gl-form-input
          :id="fields.groupId.id"
          :value="fields.groupId.value"
          :name="fields.groupId.name"
          width="sm"
          readonly
        />
      </gl-form-group>
    </template>
  </div>
</template>
