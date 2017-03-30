import eventHub from '../eventhub';

const Store = gl.issueBoards.BoardsStore;

window.gl = window.gl || {};
window.gl.issueBoards = window.gl.issueBoards || {};

export default {
  name: 'IssueCardLabels',
  props: {
    labels: { type: Array, required: true },
    list: { type: Object, required: false },
    updateFilters: { type: Boolean, required: false, default: false },
  },
  methods: {
    showLabel(label) {
      if (!this.list) return true;

      return !this.list.label || label.id !== this.list.label.id;
    },
    filterByLabel(label, e) {
      if (!this.updateFilters) return;

      const filterPath = gl.issueBoards.BoardsStore.filter.path.split('&');
      const labelTitle = encodeURIComponent(label.title);
      const param = `label_name[]=${labelTitle}`;
      const labelIndex = filterPath.indexOf(param);
      $(e.currentTarget).tooltip('hide');

      if (labelIndex === -1) {
        filterPath.push(param);
      } else {
        filterPath.splice(labelIndex, 1);
      }

      gl.issueBoards.BoardsStore.filter.path = filterPath.join('&');

      Store.updateFiltersUrl();

      eventHub.$emit('updateTokens');
    },
    labelStyle(label) {
      // TODO: What happens if label.color and/or label.textColor is not defined?

      return {
        backgroundColor: label.color,
        color: label.textColor,
      };
    },
  },
  template: `
    <div class="card-footer">
      <button
        class="label color-label has-tooltip"
        v-for="label in labels"
        type="button"
        v-if="showLabel(label)"
        @click="filterByLabel(label, $event)"
        :style="labelStyle(label)"
        :title="label.description"
        data-container="body">
        {{ label.title }}
      </button>
    </div>
  `,
};
