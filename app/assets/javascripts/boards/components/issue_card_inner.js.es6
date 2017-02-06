/* global Vue */
(() => {
  const Store = gl.issueBoards.BoardsStore;

  window.gl = window.gl || {};
  window.gl.issueBoards = window.gl.issueBoards || {};

  gl.issueBoards.IssueCardInner = Vue.extend({
    props: {
      issue: {
        type: Object,
        required: true,
      },
      issueLinkBase: {
        type: String,
        required: true,
      },
      list: {
        type: Object,
        required: false,
      },
      rootPath: {
        type: String,
        required: true,
      },
    },
    methods: {
      showLabel(label) {
        if (!this.list) return true;

        return !this.list.label || label.id !== this.list.label.id;
      },
      filterByLabel(label, e) {
        let labelToggleText = label.title;
        const labelIndex = Store.state.filters.label_name.indexOf(label.title);
        $(e.currentTarget).tooltip('hide');

        if (labelIndex === -1) {
          Store.state.filters.label_name.push(label.title);
          $('.labels-filter').prepend(`<input type="hidden" name="label_name[]" value="${label.title}" />`);
        } else {
          Store.state.filters.label_name.splice(labelIndex, 1);
          labelToggleText = Store.state.filters.label_name[0];
          $(`.labels-filter input[name="label_name[]"][value="${label.title}"]`).remove();
        }

        const selectedLabels = Store.state.filters.label_name;
        if (selectedLabels.length === 0) {
          labelToggleText = 'Label';
        } else if (selectedLabels.length > 1) {
          labelToggleText = `${selectedLabels[0]} + ${selectedLabels.length - 1} more`;
        }

        $('.labels-filter .dropdown-toggle-text').text(labelToggleText);

        Store.updateFiltersUrl();
      },
      labelStyle(label) {
        return {
          backgroundColor: label.color,
          color: label.textColor,
        };
      },
    },
    template: `
      <div>
        <h4 class="card-title">
          <i
            class="fa fa-eye-slash confidential-icon"
            v-if="issue.confidential"></i>
          <a
            :href="issueLinkBase + '/' + issue.id"
            :title="issue.title">
            {{ issue.title }}
          </a>
        </h4>
        <div class="card-footer">
          <span
            class="card-number"
            v-if="issue.id">
            #{{ issue.id }}
          </span>
          <a
            class="card-assignee has-tooltip"
            :href="rootPath + issue.assignee.username"
            :title="'Assigned to ' + issue.assignee.name"
            v-if="issue.assignee"
            data-container="body">
            <img
              class="avatar avatar-inline s20"
              :src="issue.assignee.avatar"
              width="20"
              height="20"
              :alt="'Avatar for ' + issue.assignee.name" />
          </a>
          <button
            class="label color-label has-tooltip"
            v-for="label in issue.labels"
            type="button"
            v-if="showLabel(label)"
            @click="filterByLabel(label, $event)"
            :style="labelStyle(label)"
            :title="label.description"
            data-container="body">
            {{ label.title }}
          </button>
        </div>
      </div>
    `,
  });
})();
