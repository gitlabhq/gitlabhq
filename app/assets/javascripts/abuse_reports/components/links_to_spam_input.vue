<script>
import { GlButton, GlFormGroup, GlFormInput } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  name: 'LinksToSpamInput',
  components: {
    GlButton,
    GlFormGroup,
    GlFormInput,
  },
  i18n: {
    label: s__('ReportAbuse|Link to spam'),
    addAnotherText: s__('ReportAbuse|Add another link'),
    removeLinkText: s__('ReportAbuse|Remove link'),
  },
  props: {
    previousLinks: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  data() {
    return {
      links: this.previousLinks.length > 0 ? this.previousLinks : [''],
    };
  },
  methods: {
    addAnotherInput() {
      this.links.push('');
    },
    removeInput(index) {
      this.links.splice(index, 1);
    },
  },
};
</script>
<template>
  <div>
    <template v-for="(link, index) in links">
      <div :key="index" class="row">
        <div class="gl-col-lg-8">
          <gl-form-group :label="$options.i18n.label" :label-for="`spam-link-${index}`">
            <div class="gl-flex gl-items-start gl-gap-3">
              <gl-form-input
                :id="`spam-link-${index}`"
                v-model.trim="links[index]"
                type="url"
                name="abuse_report[links_to_spam][]"
                autocomplete="off"
                class="gl-grow"
              />
              <gl-button
                v-if="index > 0"
                icon="remove"
                :aria-label="$options.i18n.removeLinkText"
                @click="removeInput(index)"
              />
            </div>
          </gl-form-group>
        </div>
      </div>
    </template>
    <div class="row">
      <div class="gl-col-lg-8">
        <gl-button variant="link" icon="plus" class="gl-float-right" @click="addAnotherInput">
          {{ $options.i18n.addAnotherText }}
        </gl-button>
      </div>
    </div>
  </div>
</template>
