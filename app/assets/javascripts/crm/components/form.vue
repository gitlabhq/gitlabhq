<script>
import { GlAlert, GlButton, GlDrawer, GlFormGroup, GlFormInput } from '@gitlab/ui';
import { get as getPropValueByPath, isEmpty } from 'lodash';
import { produce } from 'immer';
import { MountingPortal } from 'portal-vue';
import { __ } from '~/locale';
import { logError } from '~/lib/logger';
import { getFirstPropertyValue } from '~/lib/utils/common_utils';
import { INDEX_ROUTE_NAME } from '../constants';

const MSG_SAVE_CHANGES = __('Save changes');
const MSG_ERROR = __('Something went wrong. Please try again.');
const MSG_OPTIONAL = __('(optional)');
const MSG_CANCEL = __('Cancel');

/**
 * This component is a first iteration towards a general reusable Create/Update component
 *
 * There's some opportunity to improve cohesion of this module which we are planning
 * to address after solidifying the abstraction's requirements.
 *
 * Please see https://gitlab.com/gitlab-org/gitlab/-/issues/349441
 */
export default {
  components: {
    GlAlert,
    GlButton,
    GlDrawer,
    GlFormGroup,
    GlFormInput,
    MountingPortal,
  },
  props: {
    drawerOpen: {
      type: Boolean,
      required: true,
    },
    fields: {
      type: Array,
      required: true,
    },
    title: {
      type: String,
      required: true,
    },
    successMessage: {
      type: String,
      required: true,
    },
    mutation: {
      type: Object,
      required: true,
    },
    getQuery: {
      type: Object,
      required: false,
      default: null,
    },
    getQueryNodePath: {
      type: String,
      required: false,
      default: null,
    },
    existingModel: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    additionalCreateParams: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    buttonLabel: {
      type: String,
      required: false,
      default: () => MSG_SAVE_CHANGES,
    },
  },
  data() {
    const initialModel = this.fields.reduce(
      (map, field) =>
        Object.assign(map, {
          [field.name]: this.existingModel ? this.existingModel[field.name] : null,
        }),
      {},
    );

    return {
      model: initialModel,
      submitting: false,
      errorMessages: [],
    };
  },
  computed: {
    isEditMode() {
      return this.existingModel?.id;
    },
    isInvalid() {
      const { fields, model } = this;

      return fields.some((field) => {
        return field.required && isEmpty(model[field.name]);
      });
    },
    variables() {
      const { additionalCreateParams, fields, isEditMode, model } = this;

      const variables = fields.reduce(
        (map, field) =>
          Object.assign(map, {
            [field.name]: this.formatValue(model, field),
          }),
        {},
      );

      if (isEditMode) {
        return { input: { id: this.existingModel.id, ...variables } };
      }

      return { input: { ...additionalCreateParams, ...variables } };
    },
  },
  methods: {
    formatValue(model, field) {
      if (!isEmpty(model[field.name]) && field.input?.type === 'number') {
        return parseFloat(model[field.name]);
      }

      return model[field.name];
    },
    save() {
      const { mutation, variables, close } = this;

      this.submitting = true;

      return this.$apollo
        .mutate({
          mutation,
          variables,
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
          this.errorMessages = [MSG_ERROR];
        })
        .finally(() => {
          this.submitting = false;
        });
    },
    close(success) {
      if (success) {
        // This is needed so toast perists when route is changed
        this.$root.$toast.show(this.successMessage);
      }

      this.$router.replace({ name: this.$options.INDEX_ROUTE_NAME });
    },
    updateCache(store, result) {
      const { getQuery, isEditMode, getQueryNodePath } = this;

      if (isEditMode || !getQuery) return;

      const sourceData = store.readQuery(getQuery);

      const newData = produce(sourceData, (draftState) => {
        getPropValueByPath(draftState, getQueryNodePath).nodes.push(getFirstPropertyValue(result));
      });

      store.writeQuery({
        ...getQuery,
        data: newData,
      });
    },
    getFieldLabel(field) {
      const optionalSuffix = field.required ? '' : ` ${MSG_OPTIONAL}`;
      return field.label + optionalSuffix;
    },
  },
  MSG_CANCEL,
  INDEX_ROUTE_NAME,
};
</script>

<template>
  <mounting-portal mount-to="#js-crm-form-portal" append>
    <gl-drawer class="gl-drawer-responsive gl-absolute" :open="drawerOpen" @close="close(false)">
      <template #title>
        <h3>{{ title }}</h3>
      </template>
      <gl-alert v-if="errorMessages.length" variant="danger" @dismiss="errorMessages = []">
        <ul class="gl-mb-0! gl-ml-5">
          <li v-for="error in errorMessages" :key="error">
            {{ error }}
          </li>
        </ul>
      </gl-alert>
      <form @submit.prevent="save">
        <gl-form-group
          v-for="field in fields"
          :key="field.name"
          :label="getFieldLabel(field)"
          :label-for="field.name"
        >
          <gl-form-input :id="field.name" v-bind="field.input" v-model="model[field.name]" />
        </gl-form-group>
        <span class="gl-float-right">
          <gl-button data-testid="cancel-button" @click="close(false)">
            {{ $options.MSG_CANCEL }}
          </gl-button>
          <gl-button
            variant="confirm"
            :disabled="isInvalid"
            :loading="submitting"
            data-testid="save-button"
            type="submit"
            >{{ buttonLabel }}</gl-button
          >
        </span>
      </form>
    </gl-drawer>
  </mounting-portal>
</template>
