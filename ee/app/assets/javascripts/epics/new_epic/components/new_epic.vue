<script>
  import Flash from '~/flash';
  import { visitUrl } from '~/lib/utils/url_utility';
  import { s__ } from '~/locale';
  import loadingButton from '~/vue_shared/components/loading_button.vue';
  import NewEpicService from '../services/new_epic_service';

  export default {
    name: 'NewEpic',
    components: {
      loadingButton,
    },
    props: {
      endpoint: {
        type: String,
        required: true,
      },
      alignRight: {
        type: Boolean,
        required: false,
        default: false,
      },
    },
    data() {
      return {
        service: new NewEpicService(this.endpoint),
        creating: false,
        title: '',
      };
    },
    computed: {
      buttonLabel() {
        return this.creating ? s__('Creating epic') : s__('Create epic');
      },
      isCreatingDisabled() {
        return this.title.length === 0;
      },
    },
    methods: {
      createEpic() {
        this.creating = true;
        this.service.createEpic(this.title)
          .then(({ data }) => {
            visitUrl(data.web_url);
          })
          .catch(() => {
            this.creating = false;
            Flash(s__('Error creating epic'));
          });
      },
      focusInput() {
        // Wait for dropdown to appear because of transition CSS
        setTimeout(() => {
          this.$refs.title.focus();
        }, 25);
      },
    },
  };
</script>

<template>
  <div class="dropdown new-epic-dropdown">
    <button
      class="btn btn-success qa-new-epic-button"
      type="button"
      data-toggle="dropdown"
      @click="focusInput"
    >
      {{ s__('New epic') }}
    </button>
    <div
      :class="{ 'dropdown-menu-right' : alignRight }"
      class="dropdown-menu"
    >
      <input
        ref="title"
        v-model="title"
        :placeholder="s__('Title')"
        type="text"
        class="form-control qa-epic-title"
      />
      <loading-button
        :disabled="isCreatingDisabled"
        :loading="creating"
        :label="buttonLabel"
        container-class="btn btn-success btn-inverted prepend-top-10 qa-create-epic-button"
        @click.stop="createEpic"
      />
    </div>
  </div>
</template>
