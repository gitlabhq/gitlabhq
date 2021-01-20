import getDesignListQuery from 'shared_queries/design_management/get_design_list.query.graphql';
import { findVersionId } from '../utils/design_management_utils';

export default {
  apollo: {
    allVersions: {
      query: getDesignListQuery,
      variables() {
        return {
          fullPath: this.projectPath,
          iid: this.issueIid,
          atVersion: null,
        };
      },
      update: (data) => data.project.issue.designCollection.versions.nodes,
    },
  },
  inject: {
    projectPath: {
      default: '',
    },
    issueIid: {
      default: '',
    },
  },
  computed: {
    hasValidVersion() {
      return (
        this.$route.query.version &&
        this.allVersions &&
        this.allVersions.some((version) => version.id.endsWith(this.$route.query.version))
      );
    },
    designsVersion() {
      return this.hasValidVersion
        ? `gid://gitlab/DesignManagement::Version/${this.$route.query.version}`
        : null;
    },
    latestVersionId() {
      const latestVersion = this.allVersions[0];
      return latestVersion && findVersionId(latestVersion.id);
    },
    isLatestVersion() {
      if (this.allVersions.length > 0) {
        return (
          !this.$route.query.version ||
          !this.latestVersionId ||
          this.$route.query.version === this.latestVersionId
        );
      }
      return true;
    },
  },
  data() {
    return {
      allVersions: [],
    };
  },
};
