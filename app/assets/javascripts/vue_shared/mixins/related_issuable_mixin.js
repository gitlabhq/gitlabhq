import { isEmpty } from 'lodash';
import { formatDate } from '~/lib/utils/datetime_utility';
import { sprintf, __ } from '~/locale';
import timeagoMixin from '~/vue_shared/mixins/timeago';

const mixins = {
  data() {
    return {
      removeDisabled: false,
    };
  },
  props: {
    idKey: {
      type: Number,
      required: true,
    },
    displayReference: {
      type: String,
      required: true,
    },
    pathIdSeparator: {
      type: String,
      required: true,
    },
    eventNamespace: {
      type: String,
      required: false,
      default: '',
    },
    confidential: {
      type: Boolean,
      required: false,
      default: false,
    },
    title: {
      type: String,
      required: false,
      default: '',
    },
    path: {
      type: String,
      required: false,
      default: '',
    },
    state: {
      type: String,
      required: false,
      default: '',
    },
    createdAt: {
      type: String,
      required: false,
      default: '',
    },
    closedAt: {
      type: String,
      required: false,
      default: '',
    },
    mergedAt: {
      type: String,
      required: false,
      default: '',
    },
    milestone: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    dueDate: {
      type: String,
      required: false,
      default: '',
    },
    assignees: {
      type: Array,
      required: false,
      default: () => [],
    },
    weight: {
      type: Number,
      required: false,
      default: 0,
    },
    canRemove: {
      type: Boolean,
      required: false,
      default: false,
    },
    isMergeRequest: {
      type: Boolean,
      required: false,
      default: false,
    },
    pipelineStatus: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  mixins: [timeagoMixin],
  computed: {
    hasState() {
      return this.state && this.state.length > 0;
    },
    hasPipeline() {
      return this.isMergeRequest && this.pipelineStatus && Object.keys(this.pipelineStatus).length;
    },
    isOpen() {
      return this.state === 'opened' || this.state === 'reopened';
    },
    isClosed() {
      return this.state === 'closed';
    },
    isMerged() {
      return this.state === 'merged';
    },
    hasTitle() {
      return this.title.length > 0;
    },
    hasAssignees() {
      return this.assignees.length > 0;
    },
    hasMilestone() {
      return !isEmpty(this.milestone);
    },
    iconName() {
      if (this.isMergeRequest && this.isMerged) {
        return 'merge';
      }

      return this.isOpen ? 'issue-open-m' : 'issue-close';
    },
    iconClass() {
      if (this.isMergeRequest && this.isClosed) {
        return 'merge-request-status closed issue-token-state-icon-closed';
      }

      return this.isOpen
        ? 'issue-token-state-icon-open gl-text-green-500'
        : 'issue-token-state-icon-closed gl-text-blue-500';
    },
    computedLinkElementType() {
      return this.path.length > 0 ? 'a' : 'span';
    },
    computedPath() {
      return this.path.length ? this.path : null;
    },
    itemPath() {
      return this.displayReference.split(this.pathIdSeparator)[0];
    },
    itemId() {
      return this.displayReference.split(this.pathIdSeparator).pop();
    },
    createdAtInWords() {
      return this.createdAt ? this.timeFormatted(this.createdAt) : '';
    },
    createdAtTimestamp() {
      return this.createdAt ? formatDate(new Date(this.createdAt)) : '';
    },
    mergedAtTimestamp() {
      return this.mergedAt ? formatDate(new Date(this.mergedAt)) : '';
    },
    mergedAtInWords() {
      return this.mergedAt ? this.timeFormatted(this.mergedAt) : '';
    },
    closedAtInWords() {
      return this.closedAt ? this.timeFormatted(this.closedAt) : '';
    },
    closedAtTimestamp() {
      return this.closedAt ? formatDate(new Date(this.closedAt)) : '';
    },
    stateText() {
      if (this.isMerged) {
        return __('Merged');
      }

      return this.isOpen ? __('Created') : __('Closed');
    },
    stateTimeInWords() {
      if (this.isMerged) {
        return this.mergedAtInWords;
      }

      return this.isOpen ? this.createdAtInWords : this.closedAtInWords;
    },
    stateTimestamp() {
      if (this.isMerged) {
        return this.mergedAtTimestamp;
      }

      return this.isOpen ? this.createdAtTimestamp : this.closedAtTimestamp;
    },
    pipelineStatusTooltip() {
      return this.hasPipeline
        ? sprintf(__('Pipeline: %{status}'), { status: this.pipelineStatus.label })
        : '';
    },
  },
  methods: {
    onRemoveRequest() {
      let namespacePrefix = '';
      if (this.eventNamespace && this.eventNamespace.length > 0) {
        namespacePrefix = `${this.eventNamespace}`;
      }

      this.$emit(`${namespacePrefix}RemoveRequest`, this.idKey);

      this.removeDisabled = true;
    },
  },
};

export default mixins;
