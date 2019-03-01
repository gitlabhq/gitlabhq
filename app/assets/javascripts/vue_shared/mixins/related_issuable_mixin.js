import _ from 'underscore';
import { formatDate } from '~/lib/utils/datetime_utility';
import tooltip from '~/vue_shared/directives/tooltip';
import icon from '~/vue_shared/components/icon.vue';
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
  },
  components: {
    icon,
  },
  directives: {
    tooltip,
  },
  mixins: [timeagoMixin],
  computed: {
    hasState() {
      return this.state && this.state.length > 0;
    },
    isOpen() {
      return this.state === 'opened';
    },
    isClosed() {
      return this.state === 'closed';
    },
    hasTitle() {
      return this.title.length > 0;
    },
    hasMilestone() {
      return !_.isEmpty(this.milestone);
    },
    iconName() {
      return this.isOpen ? 'issue-open-m' : 'issue-close';
    },
    iconClass() {
      return this.isOpen ? 'issue-token-state-icon-open' : 'issue-token-state-icon-closed';
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
      return this.createdAt ? this.timeFormated(this.createdAt) : '';
    },
    createdAtTimestamp() {
      return this.createdAt ? formatDate(new Date(this.createdAt)) : '';
    },
    closedAtInWords() {
      return this.closedAt ? this.timeFormated(this.closedAt) : '';
    },
    closedAtTimestamp() {
      return this.closedAt ? formatDate(new Date(this.closedAt)) : '';
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
