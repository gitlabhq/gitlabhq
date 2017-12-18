import tooltip from '../../../vue_shared/directives/tooltip';

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
    eventNamespace: {
      type: String,
      required: false,
      default: '',
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
    canRemove: {
      type: Boolean,
      required: false,
      default: false,
    },
    canReorder: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  directives: {
    tooltip,
  },
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
    computedLinkElementType() {
      return this.path.length > 0 ? 'a' : 'span';
    },
    computedPath() {
      return this.path.length ? this.path : null;
    },
  },
  methods: {
    onRemoveRequest() {
      let namespacePrefix = '';
      if (this.eventNamespace && this.eventNamespace.length > 0) {
        namespacePrefix = `${this.eventNamespace}-`;
      }

      eventHub.$emit(`${namespacePrefix}removeRequest`, this.idKey);

      this.removeDisabled = true;
    },
  },
};

export default mixins;
