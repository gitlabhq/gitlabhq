/**
 * Mixin that provides computedPath computed property for repository components.
 *
 * This computed property reads from $route.params.path and normalizes it for
 * Vue Router 3/4 compatibility, returning '/' for the repository root.
 *
 * The mixin solves a critical issue where $route.params.path can become stale
 * when navigating between routes with optional parameters. By reading directly
 * from $route in a computed property, we ensure the path is always reactive and
 * up-to-date, preventing components from displaying incorrect paths.
 *
 * @example
 * import repositoryPathMixin from '~/repository/mixins/repository_path';
 *
 * export default {
 *   mixins: [repositoryPathMixin],
 *   // Now this.computedPath is available
 *   // Returns current path from route, or '/' for root
 * };
 *
 */
export default {
  computed: {
    /**
     * Computes the current repository path from route params.
     *
     * Reads directly from $route.params.path to ensure reactive updates.
     * Handles Vue Router 4 array params by joining them with '/'.
     * Returns '/' for the repository root when path param is undefined.
     *
     * @returns {string} The computed path ('/' for root, or file/folder path)
     */
    computedPath() {
      const routePath = this.$route?.params?.path;

      // Normalize path param (Vue Router 4 can return arrays for :path*)
      const normalizedRoutePath = Array.isArray(routePath) ? routePath.join('/') : routePath;

      // Return '/' for root (when path param is undefined/empty)
      return normalizedRoutePath || '/';
    },
  },
};
