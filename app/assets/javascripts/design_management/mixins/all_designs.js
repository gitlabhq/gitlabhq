import { propertyOf } from 'lodash';
import createFlash from '~/flash';
import { s__ } from '~/locale';
import getDesignListQuery from '../graphql/queries/get_design_list.query.graphql';
import allVersionsMixin from './all_versions';
import { DESIGNS_ROUTE_NAME } from '../router/constants';

export default {
  mixins: [allVersionsMixin],
  apollo: {
    designs: {
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
        if (designNodes) {
          return designNodes;
        }
        return [];
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
      },
    },
  },
  data() {
    return {
      designs: [],
      error: false,
    };
  },
};
