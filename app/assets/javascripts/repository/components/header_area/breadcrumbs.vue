<script>
import { GlBreadcrumb } from '@gitlab/ui';
import { joinPaths, escapeFileUrl, buildURLwithRefType } from '~/lib/utils/url_utility';
import getRefMixin from '~/repository/mixins/get_ref';
import projectShortPathQuery from '~/repository/queries/project_short_path.query.graphql';

export default {
  name: 'RepositoryBreadcrumbs',
  components: {
    GlBreadcrumb,
  },
  apollo: {
    projectShortPath: {
      query: projectShortPathQuery,
    },
  },
  mixins: [getRefMixin],
  inject: {
    projectRootPath: {
      default: '',
    },
  },
  props: {
    currentPath: {
      type: String,
      required: false,
      default: '',
    },
    refType: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      projectShortPath: '',
    };
  },
  computed: {
    currentDirectoryPath() {
      const splitPath = this.currentPath.split('/').filter((p) => p);

      if (this.isBlobPath) {
        splitPath.pop();
      }

      return joinPaths(...splitPath);
    },
    pathLinks() {
      return this.currentPath
        .split('/')
        .filter((p) => p !== '')
        .reduce(
          (acc, name, i) => {
            const path = joinPaths(i > 0 ? acc[i].path : '', escapeFileUrl(name));
            const isLastPath = i === this.currentPath.split('/').length - 1;
            /* eslint-disable @gitlab/no-hardcoded-urls -- these are Vue router routes defined in app/assets/javascripts/repository/router.js, acceptable in this case */
            const to =
              this.isBlobPath && isLastPath
                ? `/-/blob/${joinPaths(this.escapedRef, path)}`
                : `/-/tree/${joinPaths(this.escapedRef, path)}`;
            /* eslint-enable @gitlab/no-hardcoded-urls */
            return acc.concat({
              name,
              path,
              to: buildURLwithRefType({ path: to, refType: this.refType }),
            });
          },
          [
            {
              name: this.projectShortPath,
              path: '/',
              to: buildURLwithRefType({
                // eslint-disable-next-line @gitlab/no-hardcoded-urls -- This is a Vue router route defined in app/assets/javascripts/repository/router.js, acceptable in this case
                path: joinPaths('/-/tree', this.escapedRef),
                refType: this.refType,
              }),
            },
          ],
        );
    },
    isBlobPath() {
      return ['blobPath', 'blobPathDecoded', 'blobPathEncoded'].includes(this.$route.name);
    },
    hasCurrentPath() {
      return Boolean(this.currentPath?.trim().length);
    },
    crumbs() {
      return this.pathLinks.map(({ name, url, ...rest }) => ({ text: name, href: url, ...rest }));
    },
  },
};
</script>

<template>
  <div class="repo-breadcrumb gl-flex-grow">
    <gl-breadcrumb
      :items="crumbs"
      :data-current-path="currentDirectoryPath"
      :aria-label="__('Files breadcrumb')"
      :show-clipboard-button="hasCurrentPath"
      :path-to-copy="currentPath"
      :clipboard-tooltip-text="__('Copy file path')"
      size="md"
      class="breadcrumb-item"
    />
  </div>
</template>
