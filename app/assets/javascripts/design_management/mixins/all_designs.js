import { propertyOf } from 'lodash';
import { deprecatedCreateFlash as createFlash } from '~/flash';
import { s__ } from '~/locale';
import getDesignListQuery from '../graphql/queries/get_design_list.query.graphql';
import allVersionsMixin from './all_versions';
import { DESIGNS_ROUTE_NAME } from '../router/constants';

export default {
  mixins: [allVersionsMixin],
  apollo: {
    designCollection: {
      query: getDesignListQuery,
      variables() {
        return {
          fullPath: this.projectPath,
          iid: this.issueIid,
          atVersion: this.designsVersion,
        };
      },
      update: data => {
        const designNodes = propertyOf(data)([
          'project',
          'issue',
          'designCollection',
          'designs',
          'nodes',
        ]);
        const copyState = propertyOf(data)(['project', 'issue', 'designCollection', 'copyState']);
        return {
          designs: designNodes,
          copyState,
        };
      },
      error() {
        this.error = true;
      },
      result() {
        if (this.$route.query.version && !this.hasValidVersion) {
          createFlash(
            s__(
              'DesignManagement|Requested design version does not exist. Showing latest version instead',
            ),
          );
          this.$router.replace({ name: DESIGNS_ROUTE_NAME, query: { version: undefined } });
        }
        if (this.designCollection.copyState === 'ERROR') {
          createFlash(
            s__(
              'DesignManagement|There was an error moving your designs. Please upload your designs below.',
            ),
            'warning',
          );
        }
      },
    },
  },
  data() {
    return {
      designCollection: null,
      error: false,
    };
  },
  computed: {
    designs() {
      return this.designCollection?.designs || [];
    },
  },
};
