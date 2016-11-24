/* eslint-disable */
(() => {
  const Store = gl.issueBoards.BoardsStore;

  window.gl = window.gl || {};
  window.gl.issueBoards = window.gl.issueBoards || {};

  gl.issueBoards.BoardCard = Vue.extend({
    template: '#js-board-list-card',
    props: {
      list: Object,
      issue: Object,
      issueLinkBase: String,
      disabled: Boolean,
      index: Number
    },
    data () {
      return {
        showDetail: false,
        detailIssue: Store.detail
      };
    },
    computed: {
      issueDetailVisible () {
        return this.detailIssue.issue && this.detailIssue.issue.id === this.issue.id;
      }
    },
    methods: {
      filterByLabel (label, e) {
        let labelToggleText = label.title;
        const labelIndex = Store.state.filters['label_name'].indexOf(label.title);
        $(e.target).tooltip('hide');

        if (labelIndex === -1) {
          Store.state.filters['label_name'].push(label.title);
          $('.labels-filter').prepend(`<input type="hidden" name="label_name[]" value="${label.title}" />`);
        } else {
          Store.state.filters['label_name'].splice(labelIndex, 1);
          labelToggleText = Store.state.filters['label_name'][0];
          $(`.labels-filter input[name="label_name[]"][value="${label.title}"]`).remove();
        }

        const selectedLabels = Store.state.filters['label_name'];
        if (selectedLabels.length === 0) {
          labelToggleText = 'Label';
        } else if (selectedLabels.length > 1) {
          labelToggleText = `${selectedLabels[0]} + ${selectedLabels.length - 1} more`;
        }

        $('.labels-filter .dropdown-toggle-text').text(labelToggleText);

        Store.updateFiltersUrl();
      },
      mouseDown () {
        this.showDetail = true;
      },
      mouseMove() {
        this.showDetail = false;
      },
      showIssue (e) {
        const targetTagName = e.target.tagName.toLowerCase();

        if (targetTagName === 'a' || targetTagName === 'button') return;

        if (this.showDetail) {
          this.showDetail = false;

          if (Store.detail.issue && Store.detail.issue.id === this.issue.id) {
            Store.detail.issue = {};
          } else {
            Store.detail.issue = this.issue;
          }
        }
      }
    }
  });
})();
