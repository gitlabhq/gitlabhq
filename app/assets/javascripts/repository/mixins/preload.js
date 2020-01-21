import getFiles from '../queries/getFiles.query.graphql';
import getRefMixin from './get_ref';
import getProjectPath from '../queries/getProjectPath.query.graphql';

export default {
  mixins: [getRefMixin],
  apollo: {
    projectPath: {
      query: getProjectPath,
    },
  },
  data() {
    return { projectPath: '', loadingPath: null };
  },
  beforeRouteUpdate(to, from, next) {
    this.preload(to.params.pathMatch, next);
  },
  methods: {
    preload(path, next) {
      this.loadingPath = path.replace(/^\//, '');

      return this.$apollo
        .query({
          query: getFiles,
          variables: {
            projectPath: this.projectPath,
            ref: this.ref,
            path: this.loadingPath,
            nextPageCursor: '',
            pageSize: 100,
          },
        })
        .then(() => next());
    },
  },
};
