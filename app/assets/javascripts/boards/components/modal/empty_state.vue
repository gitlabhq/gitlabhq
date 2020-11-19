<script>
import { GlButton, GlSprintf } from '@gitlab/ui';
import { __ } from '~/locale';
import ModalStore from '../../stores/modal_store';
import modalMixin from '../../mixins/modal_mixins';

export default {
  components: {
    GlButton,
    GlSprintf,
  },
  mixins: [modalMixin],
  props: {
    newIssuePath: {
      type: String,
      required: true,
    },
    emptyStateSvg: {
      type: String,
      required: true,
    },
  },
  data() {
    return ModalStore.store;
  },
  computed: {
    contents() {
      const obj = {
        title: __("You haven't added any issues to your project yet"),
        content: __(
          'An issue can be a bug, a todo or a feature request that needs to be discussed in a project. Besides, issues are searchable and filterable.',
        ),
      };

      if (this.activeTab === 'selected') {
        obj.title = __("You haven't selected any issues yet");
        obj.content = __(
          'Go back to %{tagStart}Open issues%{tagEnd} and select some issues to add to your board.',
        );
      }

      return obj;
    },
  },
};
</script>

<template>
  <section class="empty-state d-flex mt-0 h-100">
    <div class="row w-100 my-auto mx-0">
      <div class="col-12 col-md-6 order-md-last">
        <aside class="svg-content d-none d-md-block"><img :src="emptyStateSvg" /></aside>
      </div>
      <div class="col-12 col-md-6 order-md-first">
        <div class="text-content">
          <h4>{{ contents.title }}</h4>
          <p>
            <gl-sprintf :message="contents.content">
              <template #tag="{ content }">
                <strong>{{ content }}</strong>
              </template>
            </gl-sprintf>
          </p>
          <gl-button
            v-if="activeTab === 'all'"
            :href="newIssuePath"
            category="secondary"
            variant="success"
          >
            {{ __('New issue') }}
          </gl-button>
          <gl-button
            v-if="activeTab === 'selected'"
            category="primary"
            variant="default"
            @click="changeTab('all')"
          >
            {{ __('Open issues') }}
          </gl-button>
        </div>
      </div>
    </div>
  </section>
</template>
