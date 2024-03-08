<script>
import { GlAlert, GlButton, GlDrawer, GlForm, GlFormFields } from '@gitlab/ui';
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
    GlButton,
    GlDrawer,
    GlForm,
    GlFormFields,
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
    save() {
      const { mutation, close } = this;

      this.submitting = true;

      return this.$apollo
        .mutate({
          mutation,
          variables: {
            input: {
              namespaceId: convertToGraphQLId(TYPENAME_GROUP, this.groupId),
              name: this.formValues.name,
              description: this.formValues.description,
            },
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
        <div class="gl-font-weight-bold gl-font-size-h2">
          {{ s__('Achievements|New achievement') }}
        </div>
      </template>
      <gl-alert v-if="errorMessages.length" variant="danger" @dismiss="errorMessages = []">
        <ul class="gl-mb-0! gl-ml-5">
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
        />
        <gl-button
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
