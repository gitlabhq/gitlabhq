<script>
import { __, sprintf } from '~/locale';
import ModalStore from '../../stores/modal_store';
import modalMixin from '../../mixins/modal_mixins';

export default {
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
        obj.content = sprintf(
          __(
            'Go back to %{startTag}Open issues%{endTag} and select some issues to add to your board.',
          ),
          { startTag: '<strong>', endTag: '</strong>' },
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
          <p v-html="contents.content"></p>
          <a v-if="activeTab === 'all'" :href="newIssuePath" class="btn btn-success btn-inverted">{{
            __('New issue')
          }}</a>
          <button
            v-if="activeTab === 'selected'"
            class="btn btn-default"
            type="button"
            @click="changeTab('all')"
          >
            {{ __('Open issues') }}
          </button>
        </div>
      </div>
    </div>
  </section>
</template>
