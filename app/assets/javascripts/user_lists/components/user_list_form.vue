<script>
import { GlButton, GlFormGroup, GlFormInput, GlLink, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  components: {
    GlButton,
    GlFormGroup,
    GlFormInput,
    GlLink,
    GlSprintf,
  },
  props: {
    cancelPath: {
      type: String,
      required: true,
    },
    saveButtonLabel: {
      type: String,
      required: true,
    },
    userListsDocsPath: {
      type: String,
      required: true,
    },
    userList: {
      type: Object,
      required: true,
    },
  },
  classes: {
    actionContainer: [
      'gl-py-5',
      'gl-flex',
      'gl-justify-between',
      'gl-px-4',
      'gl-border-t-solid',
      'gl-border-default',
      'gl-border-1',
      'gl-bg-subtle',
    ],
  },
  translations: {
    formLabel: s__('UserLists|Feature flag user list'),
    formSubtitle: s__(
      'UserLists|Lists allow you to define a set of users to be used with feature flags. %{linkStart}Read more about feature flag lists.%{linkEnd}',
    ),
    nameLabel: s__('UserLists|Name'),
    cancelButtonLabel: s__('UserLists|Cancel'),
  },
  data() {
    return {
      name: this.userList.name,
    };
  },
  methods: {
    submit() {
      this.$emit('submit', { ...this.userList, name: this.name });
    },
  },
};
</script>
<template>
  <div>
    <div class="gl-mt-7 gl-flex">
      <div class="gl-mr-7 gl-basis-0">
        <h4 class="gl-min-width-fit-content gl-whitespace-nowrap">
          {{ $options.translations.formLabel }}
        </h4>
        <gl-sprintf :message="$options.translations.formSubtitle" class="gl-text-subtle">
          <template #link="{ content }">
            <gl-link :href="userListsDocsPath" data-testid="user-list-docs-link">
              {{ content }}
            </gl-link>
          </template>
        </gl-sprintf>
      </div>
      <div class="gl-ml-7 gl-grow">
        <gl-form-group
          label-for="user-list-name"
          :label="$options.translations.nameLabel"
          class="gl-mb-7"
        >
          <gl-form-input id="user-list-name" v-model="name" data-testid="user-list-name" required />
        </gl-form-group>
        <div :class="$options.classes.actionContainer">
          <gl-button variant="confirm" data-testid="save-user-list" @click="submit">
            {{ saveButtonLabel }}
          </gl-button>
          <gl-button :href="cancelPath" data-testid="user-list-cancel">
            {{ $options.translations.cancelButtonLabel }}
          </gl-button>
        </div>
      </div>
    </div>
  </div>
</template>
