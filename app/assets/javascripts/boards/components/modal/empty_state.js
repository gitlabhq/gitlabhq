import Vue from 'vue';
import ModalStore from '../../stores/modal_store';
import modalMixin from '../../mixins/modal_mixins';

gl.issueBoards.ModalEmptyState = Vue.extend({
  mixins: [modalMixin],
  data() {
    return ModalStore.store;
  },
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
  computed: {
    contents() {
      const obj = {
        title: 'You haven\'t added any issues to your project yet',
        content: `
          An issue can be a bug, a todo or a feature request that needs to be
          discussed in a project. Besides, issues are searchable and filterable.
        `,
      };

      if (this.activeTab === 'selected') {
        obj.title = 'You haven\'t selected any issues yet';
        obj.content = `
          Go back to <strong>Open issues</strong> and select some issues
          to add to your board.
        `;
      }

      return obj;
    },
  },
  template: `
    <section class="empty-state">
      <div class="row">
        <div class="col-xs-12 col-sm-6 col-sm-push-6">
          <aside class="svg-content"><img :src="emptyStateSvg"/></aside>
        </div>
        <div class="col-xs-12 col-sm-6 col-sm-pull-6">
          <div class="text-content">
            <h4>{{ contents.title }}</h4>
            <p v-html="contents.content"></p>
            <a
              :href="newIssuePath"
              class="btn btn-success btn-inverted"
              v-if="activeTab === 'all'">
              New issue
            </a>
            <button
              type="button"
              class="btn btn-default"
              @click="changeTab('all')"
              v-if="activeTab === 'selected'">
              Open issues
            </button>
          </div>
        </div>
      </div>
    </section>
  `,
});
