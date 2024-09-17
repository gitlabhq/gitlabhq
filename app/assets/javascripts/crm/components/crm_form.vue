<script>
import {
  GlAlert,
  GlButton,
  GlDrawer,
  GlFormCheckbox,
  GlFormGroup,
  GlFormInput,
  GlFormSelect,
} from '@gitlab/ui';
import { get as getPropValueByPath, isEmpty } from 'lodash';
import { produce } from 'immer';
import { MountingPortal } from 'portal-vue';
import { __ } from '~/locale';
import { logError } from '~/lib/logger';
import { getFirstPropertyValue } from '~/lib/utils/common_utils';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
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
    GlFormCheckbox,
    GlFormGroup,
    GlFormInput,
    GlFormSelect,
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
    existingId: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      model: null,
      submitting: false,
      errorMessages: [],
      records: [],
      loading: true,
    };
  },
  apollo: {
    records: {
      query() {
        return this.getQuery.query;
      },
      variables() {
        return this.getQuery.variables;
      },
      update(data) {
        this.records = getPropValueByPath(data, this.getQueryNodePath).nodes || [];
        this.setInitialModel();
        this.loading = false;
      },
      error() {
        this.errorMessages = [MSG_ERROR];
      },
    },
  },
  computed: {
    isEditMode() {
      return this.existingId;
    },
    isInvalid() {
      const { fields, model } = this;

      return fields.some((field) => {
        return (
          field.required && isEmpty(model[field.name]) && typeof model[field.name] !== 'boolean'
        );
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
        return { input: { id: this.existingId, ...variables } };
      }

      return { input: { ...additionalCreateParams, ...variables } };
    },
  },
  methods: {
    setInitialModel() {
      const existingModel = this.records.find(({ id }) => id === this.existingId);
      const noModel = !this.isEditMode || !existingModel;

      this.model = this.fields.reduce(
        (map, field) =>
          Object.assign(map, {
            [field.name]: noModel ? null : this.extractValue(existingModel, field.name),
          }),
        {},
      );
    },
    extractValue(existingModel, fieldName) {
      const value = existingModel[fieldName];
      if (value != null) return value;

      /* eslint-disable-next-line @gitlab/require-i18n-strings */
      if (!fieldName.endsWith('Id')) return null;

      return existingModel[fieldName.slice(0, -2)]?.id;
    },
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
        getPropValueByPath(draftState, getQueryNodePath).nodes.push(this.getPayload(result));
      });

      store.writeQuery({
        ...getQuery,
        data: newData,
      });
    },
    getFieldLabel(field) {
      if (field.bool) return null;

      const optionalSuffix = field.required ? '' : ` ${MSG_OPTIONAL}`;
      return field.label + optionalSuffix;
    },
    getPayload(data) {
      if (!data) return null;

      const keys = Object.keys(data);
      if (keys[0] === '__typename') return data[keys[1]];

      return data[keys[0]];
    },
    getDrawerHeaderHeight() {
      return getContentWrapperHeight();
    },
  },
  MSG_CANCEL,
  INDEX_ROUTE_NAME,
  DRAWER_Z_INDEX,
};
</script>

<template>
  <mounting-portal v-if="!loading" mount-to="#js-crm-form-portal" append>
    <gl-drawer
      :header-height="getDrawerHeaderHeight()"
      class="gl-drawer-responsive"
      :open="drawerOpen"
      :z-index="$options.DRAWER_Z_INDEX"
      @close="close(false)"
    >
      <template #title>
        <h3>{{ title }}</h3>
      </template>
      <gl-alert v-if="errorMessages.length" variant="danger" @dismiss="errorMessages = []">
        <ul class="!gl-mb-0 gl-ml-5">
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
          <gl-form-select
            v-if="field.values"
            :id="field.name"
            v-model="model[field.name]"
            :options="field.values"
          />
          <gl-form-checkbox v-else-if="field.bool" :id="field.name" v-model="model[field.name]"
            ><span class="gl-font-bold">{{ field.label }}</span></gl-form-checkbox
          >
          <gl-form-input v-else :id="field.name" v-bind="field.input" v-model="model[field.name]" />
        </gl-form-group>
        <div class="gl-flex">
          <gl-button
            class="gl-mr-3"
            variant="confirm"
            :disabled="isInvalid"
            :loading="submitting"
            data-testid="save-button"
            type="submit"
            >{{ buttonLabel }}</gl-button
          >
          <gl-button data-testid="cancel-button" @click="close(false)">
            {{ $options.MSG_CANCEL }}
          </gl-button>
        </div>
      </form>
    </gl-drawer>
  </mounting-portal>
</template>
