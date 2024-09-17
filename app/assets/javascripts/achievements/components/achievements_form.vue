<script>
import {
  GlAlert,
  GlAvatar,
  GlButton,
  GlDrawer,
  GlForm,
  GlFormFields,
  GlTruncate,
} from '@gitlab/ui';
import { formValidators } from '@gitlab/ui/dist/utils';
import { produce } from 'immer';
import { get as getPropValueByPath } from 'lodash';
import { MountingPortal } from 'portal-vue';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import { __, s__, sprintf } from '~/locale';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_GROUP } from '~/graphql_shared/constants';
import { logError } from '~/lib/logger';
import { getFirstPropertyValue } from '~/lib/utils/common_utils';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { INDEX_ROUTE_NAME } from '../constants';
import createAchievementMutation from './graphql/create_achievement.mutation.graphql';

const maxLength = { name: 255, description: 1024 };

export default {
  components: {
    GlAlert,
    GlAvatar,
    GlButton,
    GlDrawer,
    GlForm,
    GlFormFields,
    GlTruncate,
    MountingPortal,
  },
  inject: ['groupFullPath', 'groupId'],
  props: {
    initialFormValues: {
      type: Object,
      required: false,
      default() {
        return {
          name: '',
          description: '',
        };
      },
    },
    isEditMode: {
      type: Boolean,
      required: false,
      default: false,
    },
    storeQuery: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      errorMessages: [],
      filename: null,
      formValues: this.initialFormValues,
      submitting: false,
    };
  },
  computed: {
    getDrawerHeaderHeight() {
      return getContentWrapperHeight();
    },
    mutation() {
      return createAchievementMutation;
    },
    previewImage() {
      return this.filename ? URL.createObjectURL(this.formValues.avatar) : null;
    },
  },
  methods: {
    close(success) {
      if (success) {
        // This is needed so toast persists when route is changed
        this.$root.$toast.show(s__('Achievements|Achievement has been added.'));
      }

      this.$router.replace({ name: this.$options.INDEX_ROUTE_NAME });
    },
    getPayload(data) {
      if (!data) return null;

      const keys = Object.keys(data);
      if (keys[0] === '__typename') return data[keys[1]];

      return data[keys[0]];
    },
    resetFile() {
      URL.revokeObjectURL(this.formValues.avatar);
      this.$refs.fileUpload.value = null;
      this.filename = null;
      this.formValues.avatar = null;
    },
    save() {
      const { mutation, close } = this;

      this.submitting = true;

      return this.$apollo
        .mutate({
          mutation,
          variables: {
            input: {
              namespaceId: convertToGraphQLId(TYPENAME_GROUP, this.groupId),
              ...this.formValues,
            },
          },
          context: {
            hasUpload: true,
          },
          update: (store, { data }) => {
            const { errors, ...result } = getFirstPropertyValue(data);

            if (errors?.length) {
              this.errorMessages = errors;
            } else {
              this.updateCache(store, result);
              close(true);
            }
          },
        })
        .catch((e) => {
          logError(e);
          this.errorMessages = [__('Something went wrong. Please try again.')];
        })
        .finally(() => {
          this.submitting = false;
        });
    },
    selectFile(e) {
      if (e.target.files.length === 0) return;

      const [file] = e.target.files;

      this.formValues.avatar = file;
      this.filename = file.name;
    },
    updateCache(store, result) {
      const { isEditMode, storeQuery } = this;

      if (isEditMode) return;

      const sourceData = store.readQuery(storeQuery);

      const newData = produce(sourceData, (draftState) => {
        getPropValueByPath(draftState, 'group.achievements').nodes.push(this.getPayload(result));
      });

      store.writeQuery({
        ...storeQuery,
        data: newData,
      });
    },
  },
  fields: {
    avatar: {
      label: s__('Achievements|Avatar'),
    },
    name: {
      label: s__('Achievements|Name'),
      validators: [
        formValidators.required(s__('Achievements|Achievement name is required.')),
        formValidators.factory(
          sprintf(
            s__('Achievements|Achievement name cannot be longer than %{length} characters.'),
            {
              length: maxLength.name,
            },
          ),
          (val) => val.length <= maxLength.name,
        ),
      ],
      groupAttrs: {
        class: 'gl-w-full',
      },
    },
    description: {
      label: s__('Achievements|Description'),
      validators: [
        formValidators.factory(
          sprintf(
            s__('Achievements|Achievement description cannot be longer than %{length} characters.'),
            {
              length: maxLength.description,
            },
          ),
          (val) => val.length <= maxLength.description,
        ),
      ],
      groupAttrs: {
        class: 'gl-w-full',
      },
    },
  },
  formId: 'achievements-form',
  DRAWER_Z_INDEX,
  INDEX_ROUTE_NAME,
};
</script>

<template>
  <mounting-portal mount-to="#js-achievements-form-portal" append>
    <gl-drawer
      :header-height="getDrawerHeaderHeight"
      class="gl-drawer-responsive"
      :open="true"
      :z-index="$options.DRAWER_Z_INDEX"
      @close="close(false)"
    >
      <template #title>
        <div class="gl-text-size-h2 gl-font-bold">
          {{ s__('Achievements|New achievement') }}
        </div>
      </template>
      <gl-alert v-if="errorMessages.length" variant="danger" @dismiss="errorMessages = []">
        <ul class="!gl-mb-0 gl-ml-5">
          <li v-for="error in errorMessages" :key="error">
            {{ error }}
          </li>
        </ul>
      </gl-alert>
      <gl-form :id="$options.formId">
        <gl-form-fields
          v-model="formValues"
          :form-id="$options.formId"
          :fields="$options.fields"
          @submit="save"
        >
          <template #input(avatar)>
            <div class="gl-flex">
              <gl-avatar :src="previewImage" shape="rect" class="gl-mr-5 gl-border-none" />
              <div class="gl-overflow-hidden">
                <div class="gl-flex">
                  <gl-button data-testid="select-file-button" @click="$refs.fileUpload.click()">
                    {{ __('Choose File...') }}
                  </gl-button>
                  <gl-button
                    v-if="filename"
                    class="gl-ml-3"
                    data-testid="reset-file-button"
                    size="small"
                    category="tertiary"
                    @click="resetFile"
                    >{{ __('Clear') }}</gl-button
                  >
                </div>
                <gl-truncate
                  v-if="filename"
                  class="gl-mt-3"
                  :text="filename"
                  position="middle"
                  with-tooltip
                />
                <input
                  ref="fileUpload"
                  data-testid="avatar-file-input"
                  type="file"
                  accept="image/*"
                  name="avatar_file"
                  class="gl-hidden"
                  @change="selectFile"
                />
              </div>
            </div>
          </template>
        </gl-form-fields>
        <gl-button
          data-testid="save-button"
          type="submit"
          variant="confirm"
          class="js-no-auto-disable"
          :loading="submitting"
          >{{ __('Save changes') }}</gl-button
        >
      </gl-form>
    </gl-drawer>
  </mounting-portal>
</template>
