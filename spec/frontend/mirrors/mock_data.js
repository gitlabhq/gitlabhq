export const createMirrorForm = () => `
  <form class="js-mirror-form" data-project-mirror-endpoint="/mirror">
    <input class="js-mirror-url js-repo-url" value="https://example.com/repository.git" />
    <input class="js-mirror-url-hidden" />
    <input class="js-mirror-protected" type="checkbox" value="1" />
    <input class="js-mirror-protected-hidden" />
    <input class="js-mirror-keep-divergent-refs" type="checkbox" value="1" />
    <input class="js-mirror-keep-divergent-refs-hidden" />
    <select class="js-auth-method"><option value="password">Password</option></select>
    <div class="js-password-group"><input class="js-password" /></div>
    <input class="js-mirror-password-field" />
  </form>
`;

export const createLegacyTable = ({ isPullMirror = false } = {}) => `
  <span class="js-mirrored-repo-count">(2)</span>
  <table>
    <tbody class="js-mirrors-table-body">
      <tr><td><button class="js-delete-mirror ${
        isPullMirror ? 'js-delete-pull-mirror' : ''
      }" data-mirror-id="1" type="button">Delete</button></td></tr>
    </tbody>
  </table>
`;
