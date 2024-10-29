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
  },
};
</script>
<template>
  <div>
    <template v-for="(link, index) in links">
      <div :key="index" class="row">
        <div class="col-lg-8">
          <gl-form-group>
            <template #label>
              <div>
                {{ $options.i18n.label }}
              </div>
            </template>
            <gl-form-input
              v-model.trim="links[index]"
              type="url"
              name="abuse_report[links_to_spam][]"
              autocomplete="off"
            />
          </gl-form-group>
        </div>
      </div>
    </template>
    <div class="row">
      <div class="col-lg-8">
        <gl-button variant="link" icon="plus" class="gl-float-right" @click="addAnotherInput">
          {{ $options.i18n.addAnotherText }}
        </gl-button>
      </div>
    </div>
  </div>
</template>
