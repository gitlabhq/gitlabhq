<script>
  import { s__ } from '~/locale';
  import Icon from '~/vue_shared/components/icon.vue';
  import ExpandButton from '~/vue_shared/components/expand_button.vue';

  export default {
    name: 'ModalDast',
    components: {
      ExpandButton,
      Icon,
    },
    props: {
      title: {
        type: String,
        required: true,
        default: '',
      },
      targetId: {
        type: String,
        required: false,
        default: '',
      },
      description: {
        type: String,
        required: true,
        default: '',
      },
      instances: {
        type: Array,
        required: false,
        default: () => ([]),
      },
    },
    computed: {
      instancesLabel() {
        return s__('ciReport|Instances');
      },
    },
    mounted() {
      $(this.$el).on('hidden.bs.modal', () => {
        this.$emit('clearData');
      });
    },
  };
</script>

<template>
  <div
    :id="targetId"
    class="modal fade"
    tabindex="-1"
    role="dialog"
  >
    <div
      class="modal-dialog modal-lg"
      role="document"
    >
      <div class="modal-content">
        <div class="modal-header">
          <button
            type="button"
            class="close"
            data-dismiss="modal"
            aria-label="Close"
          >
            <span aria-hidden="true">&times;</span>
          </button>
          <h4 class="modal-title">
            {{ title }}
          </h4>
        </div>

        <div class="modal-body">
          {{ description }}

          <h5 class="prepend-top-20">{{ instancesLabel }}</h5>
          <ul
            v-if="instances"
            class="report-block-list"
          >
            <li
              v-for="(instance, i) in instances"
              :key="i"
              class="report-block-list-item-modal failed"
            >
              <icon
                class="report-block-icon"
                name="status_failed_borderless"
                :size="32"
              />

              {{ instance.method }}

              <a
                :href="instance.uri"
                target="_blank"
                rel="noopener noreferrer nofollow"
                class="prepend-left-5"
              >
                {{ instance.uri }}
              </a>
              <expand-button v-if="instance.evidence">
                <pre
                  slot="expanded"
                  class="block report-block-dast-code prepend-top-10">{{ instance.evidence }}</pre>
              </expand-button>
            </li>
          </ul>
        </div>
      </div>
    </div>
  </div>
</template>
