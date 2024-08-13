<script>
import {
  GlFormGroup,
  GlFormInput,
  GlFormInputGroup,
  GlInputGroupText,
  GlLink,
  GlAlert,
  GlButton,
  GlButtonGroup,
  GlDropdown,
  GlDropdownItem,
  GlDropdownText,
  GlTruncate,
  GlSearchBoxByType,
} from '@gitlab/ui';
import { debounce } from 'lodash';

import { s__, __ } from '~/locale';
import { getGroupPathAvailability } from '~/rest_api';
import { createAlert } from '~/alert';
import { slugify } from '~/lib/utils/text_utility';
import axios from '~/lib/utils/axios_utils';
import { helpPagePath } from '~/helpers/help_page_helper';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { MINIMUM_SEARCH_LENGTH } from '~/graphql_shared/constants';
import { DEBOUNCE_DELAY } from '~/vue_shared/components/filtered_search_bar/constants';

import searchGroupsWhereUserCanCreateSubgroups from '../queries/search_groups_where_user_can_create_subgroups.query.graphql';

const DEBOUNCE_DURATION = 1000;

export default {
  i18n: {
    inputs: {
      name: {
        placeholder: __('My awesome group'),
        description: s__(
          'Groups|Must start with letter, digit, emoji, or underscore. Can also contain periods, dashes, spaces, and parentheses.',
        ),
        invalidFeedback: s__('Groups|Enter a descriptive name for your group.'),
        warningForUsingDotInName: s__(
          'Groups|Your group name must not contain a period if you intend to use SCIM integration, as it can lead to errors.',
        ),
      },
      path: {
        placeholder: __('my-awesome-group'),
        invalidFeedbackInvalidPattern: s__(
          'GroupSettings|Choose a group path that does not start with a dash or end with a period. It can also contain alphanumeric characters and underscores.',
        ),
        invalidFeedbackPathUnavailable: s__(
          'Groups|Group path is unavailable. Path has been replaced with a suggested available path.',
        ),
        validFeedback: s__('Groups|Group path is available.'),
      },
    },
    apiLoadingMessage: s__('Groups|Checking group URL availability...'),
    apiErrorMessage: __(
      'An error occurred while checking group path. Please refresh and try again.',
    ),
    changingUrlWarningMessage: s__('Groups|Changing group URL can have unintended side effects.'),
    learnMore: __('Learn more'),
  },
  inputSize: { md: 'lg' },
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
    GlDropdown,
    GlDropdownItem,
    GlDropdownText,
    GlTruncate,
    GlSearchBoxByType,
  },
  apollo: {
    currentUserGroups: {
      query: searchGroupsWhereUserCanCreateSubgroups,
      variables() {
        return {
          search: this.search,
        };
      },
      update(data) {
        return data.currentUser?.groups?.nodes || [];
      },
      skip() {
        const hasNotEnoughSearchCharacters =
          this.search.length > 0 && this.search.length < MINIMUM_SEARCH_LENGTH;

        return this.shouldSkipQuery || hasNotEnoughSearchCharacters;
      },
      debounce: DEBOUNCE_DELAY,
    },
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
      currentUserGroups: {},
      shouldSkipQuery: true,
      selectedGroup: {
        id: this.fields.parentId.value,
        fullPath: this.fields.parentFullPath.value,
      },
    };
  },
  computed: {
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
    isEditingGroup() {
      return this.fields.groupId.value !== '';
    },
  },
  watch: {
    name: [
      function updatePath(newName) {
        if (this.isEditingGroup || this.hasPathBeenManuallySet) return;

        this.nameFeedbackState = null;
        this.pathFeedbackState = null;
        this.apiSuggestedPath = '';
        this.path = slugify(newName);
      },
      debounce(async function updatePathWithSuggestions() {
        if (this.isEditingGroup || this.hasPathBeenManuallySet) return;

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
    async checkPathAvailability() {
      if (!this.path) return Promise.reject();

      this.apiLoading = true;

      if (this.activeApiRequestAbortController !== null) {
        this.activeApiRequestAbortController.abort();
      }

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
      this.debouncedValidatePath();
    },
    debouncedValidatePath: debounce(async function validatePath() {
      if (this.isEditingGroup && this.path === this.fields.path.value) return;

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

      this.pathInvalidFeedback = this.$options.i18n.inputs.path.invalidFeedbackInvalidPattern;
      this.pathFeedbackState = false;
    },
    handleDropdownShown() {
      if (this.shouldSkipQuery) {
        this.shouldSkipQuery = false;
      }

      this.$refs.search.focusInput();
    },
    handleDropdownItemClick({ id, fullPath }) {
      this.selectedGroup = {
        id: getIdFromGraphQLId(id),
        fullPath,
      };

      this.debouncedValidatePath();
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
      :description="$options.i18n.inputs.name.description"
      :label-for="fields.name.id"
      :invalid-feedback="$options.i18n.inputs.name.invalidFeedback"
      :state="nameFeedbackState"
    >
      <gl-form-input
        :id="fields.name.id"
        v-model="name"
        class="gl-field-error-ignore !gl-h-auto"
        required
        :name="fields.name.name"
        :placeholder="$options.i18n.inputs.name.placeholder"
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
      <gl-form-group v-if="newSubgroup" class="col-sm-6 gl-pr-0" :label="inputLabels.subgroupPath">
        <div class="input-group gl-flex-nowrap">
          <gl-button-group class="gl-w-full">
            <gl-button class="js-group-namespace-button !gl-grow-0 gl-truncate" label>
              {{ basePath }}
            </gl-button>

            <gl-dropdown
              class="js-group-namespace-dropdown gl-grow"
              toggle-class="!gl-rounded-tr-base !gl-rounded-br-base gl-w-20"
              @shown="handleDropdownShown"
            >
              <template #button-text>
                <gl-truncate
                  v-if="selectedGroup.fullPath"
                  :text="selectedGroup.fullPath"
                  position="start"
                  with-tooltip
                />
              </template>

              <gl-search-box-by-type
                ref="search"
                v-model.trim="search"
                :is-loading="$apollo.queries.currentUserGroups.loading"
              />

              <template v-if="!$apollo.queries.currentUserGroups.loading">
                <template v-if="currentUserGroups.length">
                  <gl-dropdown-item
                    v-for="group of currentUserGroups"
                    :key="group.id"
                    data-testid="select_group_dropdown_item"
                    @click="handleDropdownItemClick(group)"
                  >
                    {{ group.fullPath }}
                  </gl-dropdown-item>
                </template>
                <gl-dropdown-text v-else>{{ __('No matches found') }}</gl-dropdown-text>
              </template>
            </gl-dropdown>
          </gl-button-group>

          <div class="gl-self-center gl-pl-5">
            <span class="gl-hidden md:gl-inline">/</span>
          </div>
        </div>
      </gl-form-group>

      <gl-form-group
        :class="newSubgroup && 'col-sm-6'"
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
            class="gl-field-error-ignore !gl-h-auto"
            :name="fields.path.name"
            :value="computedPath"
            :placeholder="$options.i18n.inputs.path.placeholder"
            :maxlength="fields.path.maxLength"
            :pattern="fields.path.pattern"
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
