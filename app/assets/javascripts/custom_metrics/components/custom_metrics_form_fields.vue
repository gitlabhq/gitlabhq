<script>
import {
  GlFormInput,
  GlLink,
  GlFormGroup,
  GlFormRadioGroup,
  GlLoadingIcon,
  GlIcon,
} from '@gitlab/ui';
import { debounce } from 'lodash';
import axios from '~/lib/utils/axios_utils';
import { backOff } from '~/lib/utils/common_utils';
import csrf from '~/lib/utils/csrf';
import statusCodes from '~/lib/utils/http_status';
import { __, s__ } from '~/locale';
import { queryTypes, formDataValidator } from '../constants';

const VALIDATION_REQUEST_TIMEOUT = 10000;
const axiosCancelToken = axios.CancelToken;
let cancelTokenSource;

function backOffRequest(makeRequestCallback) {
  return backOff((next, stop) => {
    makeRequestCallback()
      .then((resp) => {
        if (resp.status === statusCodes.OK) {
          stop(resp);
        } else {
          next();
        }
      })
      // If the request is cancelled by axios
      // then consider it as noop so that its not
      // caught by subsequent catches
      .catch((thrown) => (axios.isCancel(thrown) ? undefined : stop(thrown)));
  }, VALIDATION_REQUEST_TIMEOUT);
}

export default {
  components: {
    GlFormInput,
    GlLink,
    GlFormGroup,
    GlFormRadioGroup,
    GlLoadingIcon,
    GlIcon,
  },
  props: {
    formOperation: {
      type: String,
      required: true,
    },
    formData: {
      type: Object,
      required: false,
      default: () => ({
        title: '',
        yLabel: '',
        query: '',
        unit: '',
        group: '',
        legend: '',
      }),
      validator: formDataValidator,
    },
    metricPersisted: {
      type: Boolean,
      required: false,
      default: false,
    },
    validateQueryPath: {
      type: String,
      required: true,
    },
  },
  data() {
    const group = this.formData.group.length ? this.formData.group : queryTypes.business;

    return {
      queryIsValid: null,
      queryValidateInFlight: false,
      ...this.formData,
      group,
    };
  },
  computed: {
    formIsValid() {
      return Boolean(
        this.queryIsValid &&
          this.title.length &&
          this.yLabel.length &&
          this.unit.length &&
          this.group.length,
      );
    },
    validQueryMsg() {
      return this.queryIsValid ? s__('Metrics|PromQL query is valid') : '';
    },
    invalidQueryMsg() {
      return !this.queryIsValid ? this.errorMessage : '';
    },
  },
  watch: {
    formIsValid(value) {
      this.$emit('formValidation', value);
    },
  },
  beforeMount() {
    if (this.metricPersisted) {
      this.validateQuery();
    }
  },
  methods: {
    requestValidation(query, cancelToken) {
      return backOffRequest(() =>
        axios.post(
          this.validateQueryPath,
          {
            query,
          },
          {
            cancelToken,
          },
        ),
      );
    },
    setFormState(isValid, inFlight, message) {
      this.queryIsValid = isValid;
      this.queryValidateInFlight = inFlight;
      this.errorMessage = message;
    },
    validateQuery() {
      if (!this.query) {
        this.setFormState(null, false, '');
        return;
      }
      this.setFormState(null, true, '');
      // cancel previously dispatched backoff request
      if (cancelTokenSource) {
        cancelTokenSource.cancel();
      }
      // Creating a new token for each request because
      // if a single token is used it can cancel existing requests
      // as well.
      cancelTokenSource = axiosCancelToken.source();
      this.requestValidation(this.query, cancelTokenSource.token)
        .then((res) => {
          const response = res.data;
          const { valid, error } = response.query;
          if (response.success) {
            this.setFormState(valid, false, valid ? '' : error);
          } else {
            throw new Error(__('There was an error trying to validate your query'));
          }
        })
        .catch(() => {
          this.setFormState(
            false,
            false,
            s__('Metrics|There was an error trying to validate your query'),
          );
        });
    },
    debouncedValidateQuery: debounce(function checkQuery() {
      this.validateQuery();
    }, 500),
  },
  csrfToken: csrf.token || '',
  formGroupOptions: [
    { text: __('Business'), value: queryTypes.business },
    { text: __('Response'), value: queryTypes.response },
    { text: __('System'), value: queryTypes.system },
  ],
};
</script>

<template>
  <div>
    <input ref="method" type="hidden" name="_method" :value="formOperation" />
    <input :value="$options.csrfToken" type="hidden" name="authenticity_token" />
    <gl-form-group :label="__('Name')" label-for="prometheus_metric_title" label-class="label-bold">
      <gl-form-input
        id="prometheus_metric_title"
        v-model="title"
        name="prometheus_metric[title]"
        class="form-control"
        :placeholder="s__('Metrics|e.g. Throughput')"
        data-qa-selector="custom_metric_prometheus_title_field"
        required
      />
      <span class="form-text text-muted">{{ s__('Metrics|Used as a title for the chart') }}</span>
    </gl-form-group>
    <gl-form-group :label="__('Type')" label-for="prometheus_metric_group" label-class="label-bold">
      <gl-form-radio-group
        id="metric-group"
        v-model="group"
        :options="$options.formGroupOptions"
        :checked="group"
        name="prometheus_metric[group]"
      />
      <span class="form-text text-muted">{{ s__('Metrics|For grouping similar metrics') }}</span>
    </gl-form-group>
    <gl-form-group
      :label="__('Query')"
      label-for="prometheus_metric_query"
      label-class="label-bold"
      :state="queryIsValid"
    >
      <gl-form-input
        id="prometheus_metric_query"
        v-model.trim="query"
        data-qa-selector="custom_metric_prometheus_query_field"
        name="prometheus_metric[query]"
        class="form-control"
        :placeholder="s__('Metrics|e.g. rate(http_requests_total[5m])')"
        required
        :state="queryIsValid"
        @input="debouncedValidateQuery"
      />
      <span v-if="queryValidateInFlight" class="form-text text-muted">
        <gl-loading-icon size="sm" :inline="true" class="mr-1 align-middle" />
        {{ s__('Metrics|Validating query') }}
      </span>
      <slot v-if="!queryValidateInFlight" name="valid-feedback">
        <span class="form-text cgreen">
          {{ validQueryMsg }}
        </span>
      </slot>
      <slot v-if="!queryValidateInFlight" name="invalid-feedback">
        <span class="form-text cred">
          {{ invalidQueryMsg }}
        </span>
      </slot>
      <span v-show="query.length === 0" class="form-text text-muted">
        {{ s__('Metrics|Must be a valid PromQL query.') }}
        <gl-link href="https://prometheus.io/docs/prometheus/latest/querying/basics/" tabindex="-1">
          {{ s__('Metrics|Prometheus Query Documentation') }}
          <gl-icon name="external-link" :size="12" />
        </gl-link>
      </span>
    </gl-form-group>
    <gl-form-group
      :label="s__('Metrics|Y-axis label')"
      label-for="prometheus_metric_y_label"
      label-class="label-bold"
    >
      <gl-form-input
        id="prometheus_metric_y_label"
        v-model="yLabel"
        data-qa-selector="custom_metric_prometheus_y_label_field"
        name="prometheus_metric[y_label]"
        class="form-control"
        :placeholder="s__('Metrics|e.g. Requests/second')"
        required
      />
      <span class="form-text text-muted">
        {{
          s__('Metrics|Label of the y-axis (usually the unit). The x-axis always represents time.')
        }}
      </span>
    </gl-form-group>
    <gl-form-group
      :label="s__('Metrics|Unit label')"
      label-for="prometheus_metric_unit"
      label-class="label-bold"
    >
      <gl-form-input
        id="prometheus_metric_unit"
        v-model="unit"
        data-qa-selector="custom_metric_prometheus_unit_label_field"
        name="prometheus_metric[unit]"
        class="form-control"
        :placeholder="s__('Metrics|e.g. req/sec')"
        required
      />
    </gl-form-group>
    <gl-form-group
      :label="s__('Metrics|Legend label (optional)')"
      label-for="prometheus_metric_legend"
      label-class="label-bold"
    >
      <gl-form-input
        id="prometheus_metric_legend"
        v-model="legend"
        data-qa-selector="custom_metric_prometheus_legend_label_field"
        name="prometheus_metric[legend]"
        class="form-control"
        :placeholder="s__('Metrics|e.g. HTTP requests')"
        required
      />
      <span class="form-text text-muted">
        {{
          s__(
            'Metrics|Used if the query returns a single series. If it returns multiple series, their legend labels will be picked up from the response.',
          )
        }}
      </span>
    </gl-form-group>
  </div>
</template>
