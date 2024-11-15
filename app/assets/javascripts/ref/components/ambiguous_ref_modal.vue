<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlModal, GlButton, GlSprintf } from '@gitlab/ui';
import { sprintf, s__ } from '~/locale';
import { visitUrl } from '~/lib/utils/url_utility';
import { REF_TYPE_PARAM_NAME, TAG_REF_TYPE, BRANCH_REF_TYPE } from '../constants';

export default {
  i18n: {
    title: s__('AmbiguousRef|Which reference do you want to view?'),
    description: sprintf(
      s__('AmbiguousRef|There is a branch and a tag with the same name of %{ref}.'),
    ),
    secondaryDescription: s__('AmbiguousRef|Which reference would you like to view?'),
    viewTagButton: s__('AmbiguousRef|View tag'),
    viewBranchButton: s__('AmbiguousRef|View branch'),
  },
  tagRefType: TAG_REF_TYPE,
  branchRefType: BRANCH_REF_TYPE,
  components: {
    GlModal,
    GlButton,
    GlSprintf,
  },

  props: {
    refName: {
      type: String,
      required: true,
    },
  },
  mounted() {
    this.$refs.ambiguousRefModal.show();
  },
  methods: {
    navigate(refType) {
      const url = new URL(window.location.href);
      url.searchParams.set(REF_TYPE_PARAM_NAME, refType);

      visitUrl(url.toString());
    },
  },
};
</script>

<template>
  <gl-modal
    ref="ambiguousRefModal"
    modal-id="ambiguous-ref"
    :title="$options.i18n.title"
    @primary="navigate"
  >
    <p class="gl-mb-0">
      <gl-sprintf :message="$options.i18n.description">
        <template #ref
          ><code>{{ refName }}</code></template
        >
      </gl-sprintf>
    </p>

    <p>
      {{ $options.i18n.secondaryDescription }}
    </p>

    <template #modal-footer>
      <gl-button
        category="secondary"
        variant="confirm"
        data-testid="view-tag-btn"
        @click="() => navigate($options.tagRefType)"
        >{{ $options.i18n.viewTagButton }}</gl-button
      >
      <gl-button
        category="secondary"
        variant="confirm"
        data-testid="view-branch-btn"
        @click="() => navigate($options.branchRefType)"
        >{{ $options.i18n.viewBranchButton }}</gl-button
      >
    </template>
  </gl-modal>
</template>
