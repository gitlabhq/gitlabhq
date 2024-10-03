import paginatedTreeQuery from 'shared_queries/repository/paginated_tree.query.graphql';
import projectPathQuery from '../queries/project_path.query.graphql';
import { getRefType } from '../utils/ref_type';
import getRefMixin from './get_ref';

export default {
  mixins: [getRefMixin],
  apollo: {
    projectPath: {
      query: projectPathQuery,
    },
  },
  data() {
    return { projectPath: '', loadingPath: null };
  },
  beforeRouteUpdate(to, from, next) {
    this.preload(to.params.path, next);
  },
  methods: {
    preload(path = '/', next) {
      this.loadingPath = path.replace(/^\//, '');
      return this.$apollo
        .query({
          query: paginatedTreeQuery,
          variables: {
            projectPath: this.projectPath,
            ref: this.ref,
            refType: getRefType(this.refType),
            path: this.loadingPath,
            nextPageCursor: '',
            pageSize: 100,
          },
        })
        .then(() => next());
    },
  },
};
