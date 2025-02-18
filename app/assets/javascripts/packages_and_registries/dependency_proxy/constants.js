import { helpPagePath } from '~/helpers/help_page_helper';

export const GRAPHQL_PAGE_SIZE = 20;
export const MANIFEST_PENDING_DESTRUCTION_STATUS = 'PENDING_DESTRUCTION';

export const DEPENDENCY_PROXY_HELP_PAGE_PATH = helpPagePath(
  'user/packages/dependency_proxy/_index',
  {
    anchor: 'store-a-docker-image-in-dependency-proxy-cache',
  },
);
