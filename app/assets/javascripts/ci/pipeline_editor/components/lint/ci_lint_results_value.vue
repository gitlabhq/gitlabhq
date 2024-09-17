<script>
import { isEmpty } from 'lodash';

export default {
  props: {
    item: {
      type: Object,
      required: true,
    },
    dryRun: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    tagList() {
      return this.item.tags?.join(', ');
    },
    onlyPolicy() {
      return this.item.only ? this.item.only.refs.join(', ') : this.item.only;
    },
    exceptPolicy() {
      return this.item.except ? this.item.except.refs.join(', ') : this.item.except;
    },
    scripts() {
      return {
        beforeScript: {
          show: !isEmpty(this.item.beforeScript),
          content: this.item.beforeScript?.join('\n'),
        },
        script: {
          show: !isEmpty(this.item.script),
          content: this.item.script?.join('\n'),
        },
        afterScript: {
          show: !isEmpty(this.item.afterScript),
          content: this.item.afterScript?.join('\n'),
        },
      };
    },
  },
};
</script>

<template>
  <div data-testid="ci-lint-value">
    <pre
      v-if="scripts.beforeScript.show"
      class="gl-whitespace-pre-wrap"
      data-testid="ci-lint-before-script"
      >{{ scripts.beforeScript.content }}</pre
    >
    <pre v-if="scripts.script.show" class="gl-whitespace-pre-wrap" data-testid="ci-lint-script">{{
      scripts.script.content
    }}</pre>
    <pre
      v-if="scripts.afterScript.show"
      class="gl-whitespace-pre-wrap"
      data-testid="ci-lint-after-script"
      >{{ scripts.afterScript.content }}</pre
    >

    <ul class="gl-mb-0 gl-list-none gl-pl-0">
      <li v-if="tagList">
        <b>{{ __('Tag list:') }}</b>
        {{ tagList }}
      </li>
      <div v-if="!dryRun" data-testid="ci-lint-only-except">
        <li v-if="onlyPolicy">
          <b>{{ __('Only policy:') }}</b>
          {{ onlyPolicy }}
        </li>
        <li v-if="exceptPolicy">
          <b>{{ __('Except policy:') }}</b>
          {{ exceptPolicy }}
        </li>
      </div>
      <li v-if="item.environment">
        <b>{{ __('Environment:') }}</b>
        {{ item.environment }}
      </li>
      <li v-if="item.when">
        <b>{{ __('When:') }}</b>
        {{ item.when }}
        <b v-if="item.allowFailure">{{ __('Allowed to fail') }}</b>
      </li>
    </ul>
  </div>
</template>
