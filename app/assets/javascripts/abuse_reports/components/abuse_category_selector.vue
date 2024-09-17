<script>
import { GlButton, GlDrawer, GlForm, GlFormGroup, GlFormRadioGroup } from '@gitlab/ui';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import { s__, __ } from '~/locale';
import csrf from '~/lib/utils/csrf';
import { CATEGORY_OPTIONS } from '~/abuse_reports/components/constants';

export default {
  name: 'AbuseCategorySelector',
  csrf,
  components: {
    GlButton,
    GlDrawer,
    GlForm,
    GlFormGroup,
    GlFormRadioGroup,
  },
  inject: {
    reportAbusePath: {
      default: '',
    },
  },
  props: {
    reportedUserId: {
      type: Number,
      required: true,
    },
    reportedFromUrl: {
      type: String,
      required: false,
      default: '',
    },
    showDrawer: {
      type: Boolean,
      required: true,
    },
  },
  i18n: {
    title: __('Report abuse to administrator'),
    close: __('Close'),
    label: s__('ReportAbuse|Why are you reporting this user?'),
    next: __('Next'),
  },
  CATEGORY_OPTIONS,
  data() {
    return {
      selected: '',
      mounted: false,
    };
  },
  computed: {
    getDrawerHeaderHeight() {
      // avoid calculating this in advance because it causes layout thrashing
      // https://gitlab.com/gitlab-org/gitlab/-/issues/331172#note_1269378396
      if (!this.showDrawer) return '0';
      return getContentWrapperHeight();
    },
  },
  mounted() {
    // this is required for the component to properly animate
    // when it is shown with v-if
    this.mounted = true;
  },
  methods: {
    closeDrawer() {
      this.$emit('close-drawer');
    },
  },
};
</script>
<template>
  <gl-drawer
    :header-height="getDrawerHeaderHeight"
    :z-index="300"
    :open="showDrawer && mounted"
    @close="closeDrawer"
  >
    <template #title>
      <h2 class="gl-mb-0 gl-mt-0 gl-text-size-h2 gl-leading-24" data-testid="category-drawer-title">
        {{ $options.i18n.title }}
      </h2>
    </template>
    <template #default>
      <gl-form :action="reportAbusePath" method="post" class="gl-text-left">
        <input :value="$options.csrf.token" type="hidden" name="authenticity_token" />

        <input type="hidden" name="user_id" :value="reportedUserId" data-testid="input-user-id" />
        <input
          type="hidden"
          name="abuse_report[reported_from_url]"
          :value="reportedFromUrl"
          data-testid="input-referer"
        />

        <gl-form-group :label="$options.i18n.label" label-class="gl-text-default">
          <gl-form-radio-group
            v-model="selected"
            :options="$options.CATEGORY_OPTIONS"
            name="abuse_report[category]"
            required
          />
        </gl-form-group>

        <gl-button type="submit" variant="confirm" data-testid="submit-form-button">
          {{ $options.i18n.next }}
        </gl-button>
      </gl-form>
    </template>
  </gl-drawer>
</template>
