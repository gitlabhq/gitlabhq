import { isEmpty } from 'lodash';
import { STATUS_CLOSED, STATUS_MERGED, STATUS_OPEN, STATUS_REOPENED } from '~/issues/constants';
import { localeDateFormat, newDate } from '~/lib/utils/datetime_utility';
import { __ } from '~/locale';
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
    iid: {
      type: Number,
      required: false,
      default: undefined,
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
      default: null,
    },
  },
  mixins: [timeagoMixin],
  computed: {
    hasState() {
      return this.state && this.state.length > 0;
    },
    hasPipeline() {
      return this.isMergeRequest && this.pipelineStatus;
    },
    isOpen() {
      return this.state === STATUS_OPEN || this.state === STATUS_REOPENED;
    },
    isClosed() {
      return this.state === STATUS_CLOSED;
    },
    isMerged() {
      return this.state === STATUS_MERGED;
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
    iconVariant() {
      if (this.isMergeRequest && this.isClosed) {
        return 'danger';
      }

      return this.isOpen ? 'success' : 'info';
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
      return this.createdAt ? localeDateFormat.asDateTimeFull.format(newDate(this.createdAt)) : '';
    },
    mergedAtTimestamp() {
      return this.mergedAt ? localeDateFormat.asDateTimeFull.format(newDate(this.mergedAt)) : '';
    },
    mergedAtInWords() {
      return this.mergedAt ? this.timeFormatted(this.mergedAt) : '';
    },
    closedAtInWords() {
      return this.closedAt ? this.timeFormatted(this.closedAt) : '';
    },
    closedAtTimestamp() {
      return this.closedAt ? localeDateFormat.asDateTimeFull.format(newDate(this.closedAt)) : '';
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
